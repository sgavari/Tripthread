import 'package:cloud_firestore/cloud_firestore.dart';

/// A trip that one or more users are planning together.
class Trip {
  const Trip({
    required this.id,
    required this.name,
    required this.creatorId,
    required this.memberIds,
    required this.createdAt,
    this.inviteCode,
    this.destination,
    this.imageUrl,
    this.startDate,
    this.endDate,
  });

  final String id;
  final String name;
  final String creatorId;
  final List<String> memberIds;
  final DateTime createdAt;

  /// Short code others enter to join this trip. Set once at creation and
  /// never changed. Null for trips created before this field existed.
  final String? inviteCode;

  /// Free-text place name the user entered, e.g. "Lisbon, Portugal".
  final String? destination;

  /// Best-effort representative photo for [destination], fetched once at
  /// creation time. Null if none was found.
  final String? imageUrl;
  final DateTime? startDate;
  final DateTime? endDate;

  factory Trip.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Trip(
      id: doc.id,
      name: data['name'] as String,
      creatorId: data['creatorId'] as String,
      memberIds: List<String>.from(data['memberIds'] as List),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      inviteCode: data['inviteCode'] as String?,
      destination: data['destination'] as String?,
      imageUrl: data['imageUrl'] as String?,
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'creatorId': creatorId,
      'memberIds': memberIds,
      'createdAt': FieldValue.serverTimestamp(),
      if (inviteCode != null) 'inviteCode': inviteCode,
      if (destination != null) 'destination': destination,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (startDate != null) 'startDate': Timestamp.fromDate(startDate!),
      if (endDate != null) 'endDate': Timestamp.fromDate(endDate!),
    };
  }
}
