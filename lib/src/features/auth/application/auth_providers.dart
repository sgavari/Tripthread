import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/firestore_provider.dart';
import '../../users/application/user_providers.dart';

part 'auth_providers.g.dart';

@riverpod
FirebaseAuth firebaseAuth(Ref ref) => FirebaseAuth.instance;

@riverpod
GoogleSignIn googleSignIn(Ref ref) => GoogleSignIn.instance;

/// Emits the current signed-in [User], or null when signed out.
@riverpod
Stream<User?> authStateChanges(Ref ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
}

/// Keeps the signed-in user's `users/{uid}` profile doc in sync — runs for
/// every active session (fresh sign-in *and* a resumed session on app
/// launch), not just explicit sign-in calls, so a profile always exists by
/// the time anything tries to display this user as a trip member.
@riverpod
Future<void> syncOwnUserProfile(Ref ref) async {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return;
  await upsertOwnUserProfile(ref, user);
}

@riverpod
class AuthController extends _$AuthController {
  @override
  FutureOr<void> build() {}

  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      await ref
          .read(firebaseAuthProvider)
          .signInWithEmailAndPassword(email: email, password: password);
    });
    if (result case AsyncError(:final error, :final stackTrace)) {
      debugPrint('[auth] signInWithEmail failed: $error\n$stackTrace');
    }
    // Success navigates away (AuthGate swaps to TripListScreen), which can
    // dispose this autoDispose provider before we get here.
    if (ref.mounted) state = result;
  }

  Future<void> signUpWithEmail(String email, String password) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      await ref
          .read(firebaseAuthProvider)
          .createUserWithEmailAndPassword(email: email, password: password);
    });
    if (result case AsyncError(:final error, :final stackTrace)) {
      debugPrint('[auth] signUpWithEmail failed: $error\n$stackTrace');
    }
    if (ref.mounted) state = result;
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      final googleSignIn = ref.read(googleSignInProvider);
      await googleSignIn.initialize();
      final account = await googleSignIn.authenticate();
      final googleAuth = account.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      await ref.read(firebaseAuthProvider).signInWithCredential(credential);
    });
    if (result case AsyncError(:final error, :final stackTrace)) {
      debugPrint('[auth] signInWithGoogle failed: $error\n$stackTrace');
    }
    if (ref.mounted) state = result;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      await ref.read(firebaseAuthProvider).sendPasswordResetEmail(email: email);
    });
    if (result case AsyncError(:final error, :final stackTrace)) {
      debugPrint('[auth] sendPasswordResetEmail failed: $error\n$stackTrace');
    }
    if (ref.mounted) state = result;
  }

  Future<void> signOut() async {
    await ref.read(firebaseAuthProvider).signOut();
    // firebaseAuth.signOut() triggers authStateChanges -> AuthGate swaps
    // back to SignInScreen, which can dispose this autoDispose provider
    // before we get here.
    if (!ref.mounted) return;
    await ref.read(googleSignInProvider).signOut();
  }

  /// Deletes the account and this user's own data (profile doc, and their
  /// membership in every trip they're part of). Chat messages and expenses
  /// they created stay in place — like any group messaging app, content
  /// shared with a group isn't retroactively erased when one member leaves,
  /// and yanking it out would corrupt other members' expense splits/history.
  ///
  /// Firebase requires a *recent* sign-in for this; if the session is old,
  /// it throws `requires-recent-login` — callers should catch that, sign
  /// the user out, and ask them to sign back in and immediately retry.
  Future<void> deleteAccount() async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return;
    final uid = user.uid;

    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      final firestore = ref.read(firestoreProvider);

      final myTrips = await firestore
          .collection('trips')
          .where('memberIds', arrayContains: uid)
          .get();
      for (final tripDoc in myTrips.docs) {
        await tripDoc.reference.update({
          'memberIds': FieldValue.arrayRemove([uid]),
        });
      }

      await firestore.collection('users').doc(uid).delete();
      await user.delete();
    });
    if (ref.mounted) state = result;
  }
}
