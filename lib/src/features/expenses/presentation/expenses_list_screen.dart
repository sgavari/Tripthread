import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/color_utils.dart';
import '../../auth/application/auth_providers.dart';
import '../../trips/application/trip_providers.dart';
import '../../trips/domain/trip.dart';
import '../application/expense_providers.dart';
import 'trip_expenses_screen.dart';

/// Every trip you're in, each row showing your net balance for that trip
/// at a glance. Tapping a row opens the full expense ledger for it.
class ExpensesListScreen extends ConsumerWidget {
  const ExpensesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(myTripsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Expenses')),
      body: tripsAsync.when(
        data: (trips) => trips.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Join or create a trip to start tracking expenses.',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ListView.separated(
                itemCount: trips.length,
                separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
                itemBuilder: (context, index) => _ExpenseListTile(trip: trips[index]),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Could not load trips: $error')),
      ),
    );
  }
}

class _ExpenseListTile extends ConsumerWidget {
  const _ExpenseListTile({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(tripExpensesProvider(trip.id));
    final currentUserId = ref.watch(firebaseAuthProvider).currentUser?.uid;
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: colorForKey(trip.id),
        backgroundImage:
            trip.imageUrl != null ? NetworkImage(trip.imageUrl!) : null,
        child: trip.imageUrl == null
            ? Text(
                trip.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(color: Colors.white),
              )
            : null,
      ),
      title: Text(trip.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: expensesAsync.when(
        data: (expenses) => Text('${expenses.length} expense(s)'),
        loading: () => const Text('…'),
        error: (_, _) => const SizedBox.shrink(),
      ),
      trailing: expensesAsync.maybeWhen(
        data: (expenses) {
          if (currentUserId == null) return null;
          final balance = computeBalances(expenses)[currentUserId] ?? 0;
          if (balance.abs() < 0.005) {
            return Text('Settled', style: TextStyle(color: colorScheme.onSurfaceVariant));
          }
          final isOwed = balance > 0;
          return Text(
            '${isOwed ? '+' : '-'}\$${balance.abs().toStringAsFixed(2)}',
            style: TextStyle(
              color: isOwed ? Colors.green.shade700 : colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          );
        },
        orElse: () => null,
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TripExpensesScreen(tripId: trip.id, tripName: trip.name),
        ),
      ),
    );
  }
}
