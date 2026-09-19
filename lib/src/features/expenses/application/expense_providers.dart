import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/firestore_provider.dart';
import '../../auth/application/auth_providers.dart';
import '../domain/expense.dart';

part 'expense_providers.g.dart';

/// Live-updating expense history for a trip, newest first.
@riverpod
Stream<List<Expense>> tripExpenses(Ref ref, String tripId) {
  return ref
      .watch(firestoreProvider)
      .collection('trips')
      .doc(tripId)
      .collection('expenses')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(Expense.fromFirestore).toList());
}

/// Net balance per uid across a set of expenses: positive means that
/// person is owed money overall, negative means they owe money overall.
/// Purely a client-side reduction — no simplification into "who pays whom"
/// beyond that, which is enough for a small trip group to settle up by eye.
Map<String, double> computeBalances(List<Expense> expenses) {
  final balances = <String, double>{};
  for (final expense in expenses) {
    balances.update(
      expense.paidByUid,
      (value) => value + expense.amount,
      ifAbsent: () => expense.amount,
    );
    for (final uid in expense.splitAmongUids) {
      balances.update(
        uid,
        (value) => value - expense.shareAmount,
        ifAbsent: () => -expense.shareAmount,
      );
    }
  }
  return balances;
}

@riverpod
class ExpenseController extends _$ExpenseController {
  @override
  FutureOr<void> build() {}

  Future<void> addExpense({
    required String tripId,
    required String description,
    required double amount,
    required String paidByUid,
    required List<String> splitAmongUids,
  }) async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return;
    final trimmed = description.trim();
    if (trimmed.isEmpty || amount <= 0 || splitAmongUids.isEmpty) return;

    state = const AsyncLoading();
    final expense = Expense(
      id: '', // assigned by Firestore
      description: trimmed,
      amount: amount,
      paidByUid: paidByUid,
      splitAmongUids: splitAmongUids,
      createdByUid: user.uid,
      createdAt: null,
    );
    final result = await AsyncValue.guard(() async {
      await ref
          .read(firestoreProvider)
          .collection('trips')
          .doc(tripId)
          .collection('expenses')
          .add(expense.toFirestore());
    });
    if (ref.mounted) state = result;
  }

  Future<void> deleteExpense(String tripId, String expenseId) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      await ref
          .read(firestoreProvider)
          .collection('trips')
          .doc(tripId)
          .collection('expenses')
          .doc(expenseId)
          .delete();
    });
    if (ref.mounted) state = result;
  }
}
