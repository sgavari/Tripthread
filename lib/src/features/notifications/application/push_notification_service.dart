import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/navigation.dart';
import '../../auth/application/auth_providers.dart';
import '../../chat/presentation/chat_screen.dart';
import '../../users/application/user_providers.dart';

part 'push_notification_service.g.dart';

@riverpod
FirebaseMessaging firebaseMessaging(Ref ref) => FirebaseMessaging.instance;

/// Requests notification permission, registers this device's FCM token,
/// keeps it fresh, and wires up tap-to-open-chat — activated once per
/// session by watching it (from [AuthGate]). Result unused; this is a
/// side-effecting bootstrap, not a value anything reads.
///
/// Best-effort everywhere: push isn't available on every platform we test
/// on (e.g. desktop/web need extra platform setup we haven't done yet), so
/// failures here are logged and swallowed rather than surfaced to the user
/// — a missing push token should never block using the app.

/// Uids we've already run the permission/token dance for this app run —
/// authStateChanges() can re-emit the *same* user (e.g. on token refresh),
/// and without this guard each of those re-emissions would redo all of it
/// for no reason.
final _registeredUids = <String>{};

@riverpod
Future<void> registerPushNotifications(Ref ref) async {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return;
  if (!_registeredUids.add(user.uid)) return;

  final messaging = ref.read(firebaseMessagingProvider);

  try {
    final settings = await messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    final token = await messaging.getToken();
    if (token != null) await registerFcmToken(ref, user.uid, token);

    final refreshSub = messaging.onTokenRefresh.listen(
      (newToken) => registerFcmToken(ref, user.uid, newToken),
    );
    ref.onDispose(refreshSub.cancel);
  } catch (error) {
    debugPrint('[push] setup failed (expected on unsupported platforms): $error');
    return;
  }

  final foregroundSub = FirebaseMessaging.onMessage.listen(_showForegroundBanner);
  ref.onDispose(foregroundSub.cancel);

  final openedSub = FirebaseMessaging.onMessageOpenedApp.listen(_openChatFrom);
  ref.onDispose(openedSub.cancel);

  // App was launched fresh by tapping a notification (was fully terminated,
  // not just backgrounded) — onMessageOpenedApp won't fire for this one.
  final initialMessage = await messaging.getInitialMessage();
  if (initialMessage != null) _openChatFrom(initialMessage);
}

void _showForegroundBanner(RemoteMessage message) {
  final notification = message.notification;
  if (notification == null) return;
  rootScaffoldMessengerKey.currentState?.showSnackBar(
    SnackBar(
      content: Text('${notification.title}: ${notification.body}'),
      action: SnackBarAction(
        label: 'Open',
        onPressed: () => _openChatFrom(message),
      ),
    ),
  );
}

void _openChatFrom(RemoteMessage message) {
  final tripId = message.data['tripId'] as String?;
  if (tripId == null) return;
  final tripName = message.data['tripName'] as String? ?? '';
  rootNavigatorKey.currentState?.push(
    MaterialPageRoute(
      builder: (_) => ChatScreen(tripId: tripId, tripName: tripName),
    ),
  );
}
