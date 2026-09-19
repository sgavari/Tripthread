import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/firestore_provider.dart';
import '../../auth/application/auth_providers.dart';
import '../domain/trip.dart';
import 'destination_image_service.dart';

part 'trip_providers.g.dart';

/// Characters chosen to avoid visual ambiguity when read aloud or typed:
/// no 0/O, 1/I/L.
const _inviteCodeAlphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

String _generateInviteCode({int length = 6}) {
  final random = Random.secure();
  return List.generate(
    length,
    (_) => _inviteCodeAlphabet[random.nextInt(_inviteCodeAlphabet.length)],
  ).join();
}

/// A member's nickname for this specific trip, if they set one — distinct
/// from their account-wide display name, e.g. "Coach" on this trip only.
@riverpod
Future<String?> tripMemberNickname(Ref ref, String tripId, String uid) async {
  final doc = await ref
      .read(firestoreProvider)
      .collection('trips')
      .doc(tripId)
      .collection('members')
      .doc(uid)
      .get();
  return doc.data()?['nickname'] as String?;
}

/// Live-updating list of trips the current user belongs to, newest first.
///
/// Emits an empty list while signed out.
@riverpod
Stream<List<Trip>> myTrips(Ref ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return Stream.value(const []);

  return ref
      .watch(firestoreProvider)
      .collection('trips')
      .where('memberIds', arrayContains: user.uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(Trip.fromFirestore).toList());
}

@riverpod
class TripController extends _$TripController {
  @override
  FutureOr<void> build() {}

  Future<void> createTrip({
    required String name,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    String? nickname,
  }) async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return;

    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      final imageUrl = destination == null
          ? null
          : await ref
              .read(destinationImageServiceProvider)
              .lookupImageUrl(destination);

      final firestore = ref.read(firestoreProvider);
      final tripRef = firestore.collection('trips').doc();
      var inviteCode = _generateInviteCode();

      final trip = Trip(
        id: tripRef.id,
        name: name,
        creatorId: user.uid,
        memberIds: [user.uid],
        createdAt: DateTime.now(), // overwritten by serverTimestamp
        inviteCode: inviteCode,
        destination: destination,
        imageUrl: imageUrl,
        startDate: startDate,
        endDate: endDate,
      );
      // Write the trip first — the invite doc's and member doc's security
      // rules need to read this trip back to confirm membership, which
      // only works once it's actually committed (can't batch atomically).
      await tripRef.set(trip.toFirestore());

      if (nickname != null && nickname.isNotEmpty) {
        await tripRef.collection('members').doc(user.uid).set({
          'nickname': nickname,
        });
      }

      // Retry on the (very unlikely) chance a freshly-generated code
      // collides with an existing one.
      for (var attempt = 0; attempt < 5; attempt++) {
        try {
          await firestore.collection('tripInvites').doc(inviteCode).set({
            'tripId': tripRef.id,
          });
          return;
        } on FirebaseException catch (e) {
          if (e.code != 'permission-denied' || attempt == 4) rethrow;
          inviteCode = _generateInviteCode();
          await tripRef.update({'inviteCode': inviteCode});
        }
      }
    });
    if (ref.mounted) state = result;
  }

  Future<void> joinTripByCode(String code, {String? nickname}) async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return;

    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      final firestore = ref.read(firestoreProvider);
      final normalizedCode = code.trim().toUpperCase();
      final inviteDoc =
          await firestore.collection('tripInvites').doc(normalizedCode).get();
      if (!inviteDoc.exists) {
        throw StateError('That invite code doesn\'t match any trip.');
      }
      final tripId = inviteDoc.data()!['tripId'] as String;
      final tripRef = firestore.collection('trips').doc(tripId);
      await tripRef.update({
        'memberIds': FieldValue.arrayUnion([user.uid]),
      });

      if (nickname != null && nickname.isNotEmpty) {
        // Needs the memberIds update above to have landed first — the
        // member doc's write rule reads the trip back to confirm
        // membership.
        await tripRef.collection('members').doc(user.uid).set({
          'nickname': nickname,
        });
      }
    });
    if (ref.mounted) state = result;
  }

  Future<void> updateTrip({
    required String tripId,
    required String name,
    String? destination,
    String? previousDestination,
    String? previousImageUrl,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      // Re-fetch the photo if the destination text changed, or retry if it
      // never found one last time — but leave a working photo alone on
      // unrelated edits (name/dates) so a good match never gets clobbered.
      final destinationChanged = destination != previousDestination;
      final shouldLookUp =
          destination != null && (destinationChanged || previousImageUrl == null);
      final imageUrl = !shouldLookUp
          ? (destinationChanged ? null : previousImageUrl)
          : await ref
              .read(destinationImageServiceProvider)
              .lookupImageUrl(destination);

      await ref.read(firestoreProvider).collection('trips').doc(tripId).update({
        'name': name,
        'destination': destination ?? FieldValue.delete(),
        'imageUrl': imageUrl ?? FieldValue.delete(),
        'startDate':
            startDate != null ? Timestamp.fromDate(startDate) : FieldValue.delete(),
        'endDate':
            endDate != null ? Timestamp.fromDate(endDate) : FieldValue.delete(),
      });
    });
    if (ref.mounted) state = result;
  }

  Future<void> deleteTrip(String tripId) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      await ref.read(firestoreProvider).collection('trips').doc(tripId).delete();
    });
    if (ref.mounted) state = result;
  }

  /// Removes the current user from a trip they don't own. The creator can't
  /// leave their own trip — they'd need to delete it instead.
  Future<void> leaveTrip(String tripId) async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      await ref.read(firestoreProvider).collection('trips').doc(tripId).update({
        'memberIds': FieldValue.arrayRemove([user.uid]),
      });
    });
    if (ref.mounted) state = result;
  }

  /// Creator-only: removes another member from the trip (e.g. after an
  /// abusive-content report). Doesn't touch anything the removed member
  /// already posted — same reasoning as account deletion.
  Future<void> removeMember(String tripId, String uid) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      await ref.read(firestoreProvider).collection('trips').doc(tripId).update({
        'memberIds': FieldValue.arrayRemove([uid]),
      });
    });
    if (ref.mounted) state = result;
  }
}
