import 'package:cloud_firestore/cloud_firestore.dart';

/// Public profile info for a user, denormalized into its own collection so
/// other users (e.g. fellow trip members) can resolve a uid to a name/photo
/// without needing backend/admin access to Firebase Auth's user records.
class AppUser {
  const AppUser({
    required this.uid,
    this.displayName,
    this.email,
    this.photoUrl,
  });

  final String uid;
  final String? displayName;
  final String? email;
  final String? photoUrl;

  /// Best available label for showing this user in a list.
  String get label => displayName ?? email ?? uid;

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return AppUser(
      uid: doc.id,
      displayName: data['displayName'] as String?,
      email: data['email'] as String?,
      photoUrl: data['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (displayName != null) 'displayName': displayName,
      if (email != null) 'email': email,
      if (photoUrl != null) 'photoUrl': photoUrl,
    };
  }
}
