import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/color_utils.dart';
import '../../auth/application/auth_providers.dart';
import '../../trips/application/trip_providers.dart';
import '../../users/application/user_providers.dart';
import '../application/expense_providers.dart';
import '../domain/expense.dart';
import 'add_expense_screen.dart';

class TripExpensesScreen extends ConsumerWidget {
  const TripExpensesScreen({super.key, required this.tripId, required this.tripName});

  final String tripId;
  final String tripName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(tripExpensesProvider(tripId));

    return Scaffold(
      appBar: AppBar(title: Text(tripName)),
      body: expensesAsync.when(
        data: (expenses) {
          if (expenses.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No expenses yet. Add the first one to start splitting costs.',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final balances = computeBalances(expenses);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _BalanceSummary(tripId: tripId, balances: balances),
              const SizedBox(height: 24),
              Text(
                'All expenses',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              for (final expense in expenses)
                _ExpenseTile(tripId: tripId, expense: expense),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Could not load expenses: $error')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => AddExpenseScreen(tripId: tripId)),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add expense'),
      ),
    );
  }
}

class _BalanceSummary extends StatelessWidget {
  const _BalanceSummary({required this.tripId, required this.balances});

  final String tripId;
  final Map<String, double> balances;

  @override
  Widget build(BuildContext context) {
    final entries = balances.entries.where((e) => e.value.abs() >= 0.005).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Balances',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (entries.isEmpty)
              const Text('Everyone is settled up.')
            else
              for (final entry in entries)
                _BalanceRow(tripId: tripId, uid: entry.key, amount: entry.value),
          ],
        ),
      ),
    );
  }
}

class _BalanceRow extends ConsumerWidget {
  const _BalanceRow({required this.tripId, required this.uid, required this.amount});

  final String tripId;
  final String uid;
  final double amount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nickname = ref.watch(tripMemberNicknameProvider(tripId, uid)).value;
    final profile = ref.watch(userProfileProvider(uid)).value;
    final label = nickname ?? profile?.label ?? uid;
    final isOwed = amount > 0;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(isOwed ? '$label is owed' : '$label owes')),
          Text(
            '\$${amount.abs().toStringAsFixed(2)}',
            style: TextStyle(
              color: isOwed ? Colors.green.shade700 : colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseTile extends ConsumerWidget {
  const _ExpenseTile({required this.tripId, required this.expense});

  final String tripId;
  final Expense expense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(firebaseAuthProvider).currentUser?.uid;
    final canDelete = expense.createdByUid == currentUserId;

    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorForKey(expense.id.isEmpty ? expense.paidByUid : expense.id),
          child: const Icon(Icons.receipt_long, color: Colors.white, size: 20),
        ),
        title: Text(expense.description),
        subtitle: _PaidBySubtitle(tripId: tripId, expense: expense),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '\$${expense.amount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (canDelete)
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                tooltip: 'Delete expense',
                onPressed: () => _confirmDelete(context, ref),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete expense?'),
        content: Text('Remove "${expense.description}" from this trip.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(expenseControllerProvider.notifier).deleteExpense(tripId, expense.id);
    }
  }
}

class _PaidBySubtitle extends ConsumerWidget {
  const _PaidBySubtitle({required this.tripId, required this.expense});

  final String tripId;
  final Expense expense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nickname = ref.watch(tripMemberNicknameProvider(tripId, expense.paidByUid)).value;
    final profile = ref.watch(userProfileProvider(expense.paidByUid)).value;
    final label = nickname ?? profile?.label ?? expense.paidByUid;
    final splitCount = expense.splitAmongUids.length;
    return Text('Paid by $label · split $splitCount way${splitCount == 1 ? '' : 's'}');
  }
}
