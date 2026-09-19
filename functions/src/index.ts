import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { logger } from "firebase-functions/v2";

initializeApp();
const db = getFirestore();

/**
 * Notifies every other member of a trip when a new chat message lands.
 * Trigger only (no return value the client waits on) — best-effort: a
 * failed push should never affect the message write that already
 * succeeded on the client.
 */
export const notifyOnNewMessage = onDocumentCreated(
  "trips/{tripId}/messages/{messageId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const { tripId } = event.params;
    const message = snapshot.data() as { senderId: string; text: string };

    const tripSnap = await db.collection("trips").doc(tripId).get();
    const trip = tripSnap.data() as { name: string; memberIds: string[] } | undefined;
    if (!trip) return;

    const recipientIds = trip.memberIds.filter((id) => id !== message.senderId);
    if (recipientIds.length === 0) return;

    const senderLabel = await resolveSenderLabel(tripId, message.senderId);

    const tokensByUid = new Map<string, string[]>();
    await Promise.all(
      recipientIds.map(async (uid) => {
        const userSnap = await db.collection("users").doc(uid).get();
        const tokens = (userSnap.data()?.fcmTokens as string[] | undefined) ?? [];
        if (tokens.length > 0) tokensByUid.set(uid, tokens);
      })
    );

    const allTokens = [...tokensByUid.values()].flat();
    if (allTokens.length === 0) return;

    const response = await getMessaging().sendEachForMulticast({
      tokens: allTokens,
      notification: {
        title: trip.name,
        body: `${senderLabel}: ${message.text}`,
      },
      data: { tripId, tripName: trip.name },
    });

    await cleanUpDeadTokens(tokensByUid, allTokens, response.responses);
  }
);

async function resolveSenderLabel(tripId: string, senderId: string): Promise<string> {
  const memberSnap = await db
    .collection("trips")
    .doc(tripId)
    .collection("members")
    .doc(senderId)
    .get();
  const nickname = memberSnap.data()?.nickname as string | undefined;
  if (nickname) return nickname;

  const userSnap = await db.collection("users").doc(senderId).get();
  const user = userSnap.data() as { displayName?: string; email?: string } | undefined;
  return user?.displayName ?? user?.email ?? "Someone";
}

/** Drops tokens FCM reports as no-longer-registered, so we stop paying the
 * lookup cost for them on every future message. */
async function cleanUpDeadTokens(
  tokensByUid: Map<string, string[]>,
  allTokens: string[],
  responses: { success: boolean; error?: { code: string } }[]
): Promise<void> {
  const deadTokens = new Set(
    responses
      .map((result, i) => (!result.success && result.error?.code === "messaging/registration-token-not-registered" ? allTokens[i] : null))
      .filter((t): t is string => t !== null)
  );
  if (deadTokens.size === 0) return;

  await Promise.all(
    [...tokensByUid.entries()].map(async ([uid, tokens]) => {
      const stale = tokens.filter((t) => deadTokens.has(t));
      if (stale.length === 0) return;
      await db
        .collection("users")
        .doc(uid)
        .update({ fcmTokens: tokens.filter((t) => !deadTokens.has(t)) });
      logger.info(`Removed ${stale.length} dead FCM token(s) for user ${uid}`);
    })
  );
}
