import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/firestore_provider.dart';
import '../../auth/application/auth_providers.dart';
import '../domain/chat_message.dart';

part 'chat_providers.g.dart';

/// Live-updating chat history for a trip, newest last (ready for a
/// bottom-anchored chat list).
@riverpod
Stream<List<ChatMessage>> tripMessages(Ref ref, String tripId) {
  return ref
      .watch(firestoreProvider)
      .collection('trips')
      .doc(tripId)
      .collection('messages')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(ChatMessage.fromFirestore).toList());
}

/// Just the most recent message in a trip, for a chat-list preview row.
/// Null while the trip has no messages yet.
@riverpod
Stream<ChatMessage?> tripLatestMessage(Ref ref, String tripId) {
  return ref
      .watch(firestoreProvider)
      .collection('trips')
      .doc(tripId)
      .collection('messages')
      .orderBy('createdAt', descending: true)
      .limit(1)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.isEmpty ? null : ChatMessage.fromFirestore(snapshot.docs.first));
}

@riverpod
class ChatController extends _$ChatController {
  @override
  FutureOr<void> build() {}

  /// Flags a message for out-of-band moderation review (App Store Guideline
  /// 1.2 requires a report mechanism for apps with user-to-user messaging).
  Future<void> reportMessage({
    required String tripId,
    required String messageId,
    required String reportedUid,
    required String text,
  }) async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return;

    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      await ref.read(firestoreProvider).collection('messageReports').add({
        'tripId': tripId,
        'messageId': messageId,
        'reportedUid': reportedUid,
        'reporterUid': user.uid,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
    if (ref.mounted) state = result;
  }

  Future<void> sendMessage(String tripId, String text) async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    state = const AsyncLoading();
    final message = ChatMessage(
      id: '', // assigned by Firestore
      senderId: user.uid,
      text: trimmed,
      createdAt: null,
    );
    final result = await AsyncValue.guard(() async {
      await ref
          .read(firestoreProvider)
          .collection('trips')
          .doc(tripId)
          .collection('messages')
          .add(message.toFirestore());
    });
    if (ref.mounted) state = result;
  }
}
