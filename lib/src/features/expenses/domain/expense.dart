import 'package:cloud_firestore/cloud_firestore.dart';

/// A single trip expense, split evenly among whichever members were
/// selected at the time it was added (not necessarily the full trip roster
/// — someone who skipped an activity can be left out).
class Expense {
  const Expense({
    required this.id,
    required this.description,
    required this.amount,
    required this.paidByUid,
    required this.splitAmongUids,
    required this.createdByUid,
    required this.createdAt,
  });

  final String id;
  final String description;
  final double amount;
  final String paidByUid;
  final List<String> splitAmongUids;
  final String createdByUid;

  /// Null for the brief window between an optimistic local write and the
  /// server assigning its actual timestamp.
  final DateTime? createdAt;

  /// Each person in [splitAmongUids] owes an equal share of [amount].
  double get shareAmount =>
      splitAmongUids.isEmpty ? 0 : amount / splitAmongUids.length;

  factory Expense.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Expense(
      id: doc.id,
      description: data['description'] as String,
      amount: (data['amount'] as num).toDouble(),
      paidByUid: data['paidByUid'] as String,
      splitAmongUids: List<String>.from(data['splitAmongUids'] as List),
      createdByUid: data['createdByUid'] as String,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'description': description,
      'amount': amount,
      'paidByUid': paidByUid,
      'splitAmongUids': splitAmongUids,
      'createdByUid': createdByUid,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
