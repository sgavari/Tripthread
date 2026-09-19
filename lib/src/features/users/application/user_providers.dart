import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/firestore_provider.dart';
import '../domain/app_user.dart';

part 'user_providers.g.dart';

/// Fetches a single user's public profile by uid. Cached per-uid by
/// Riverpod, so resolving the same member across many trips/screens is one
/// read, not one per usage.
@riverpod
Future<AppUser?> userProfile(Ref ref, String uid) async {
  final doc =
      await ref.read(firestoreProvider).collection('users').doc(uid).get();
  return doc.exists ? AppUser.fromFirestore(doc) : null;
}

/// Writes/refreshes the signed-in user's own public profile doc from their
/// Firebase Auth record. Call after any successful sign-in — cheap (merge
/// write) and keeps display name/photo in sync if they change upstream
/// (e.g. a different Google photo next login).
Future<void> upsertOwnUserProfile(Ref ref, User user) async {
  final profile = AppUser(
    uid: user.uid,
    displayName: user.displayName,
    email: user.email,
    photoUrl: user.photoURL,
  );
  await ref
      .read(firestoreProvider)
      .collection('users')
      .doc(user.uid)
      .set(profile.toFirestore(), SetOptions(merge: true));
}

/// Adds this device's FCM token to the user's token list (a user can have
/// several — one per device). `set(merge: true)` rather than `update` so
/// this can't race ahead of [upsertOwnUserProfile] and hit a missing doc.
Future<void> registerFcmToken(Ref ref, String uid, String token) async {
  await ref.read(firestoreProvider).collection('users').doc(uid).set(
    {
      'fcmTokens': FieldValue.arrayUnion([token]),
    },
    SetOptions(merge: true),
  );
}
