import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/color_utils.dart';
import '../../trips/application/trip_providers.dart';
import '../../trips/domain/trip.dart';
import '../../trips/presentation/trip_form_screen.dart';

/// Landing dashboard: a quick "create trip" action plus a glance at what's
/// coming up. The full, exhaustive list (with all CRUD) lives on the Trips
/// tab — this is a curated subset, not a duplicate of it.
class HomeOverviewScreen extends ConsumerWidget {
  const HomeOverviewScreen({super.key});

  List<Trip> _upcoming(List<Trip> trips) {
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final dated = trips
        .where((t) => t.startDate != null && !t.startDate!.isBefore(startOfToday))
        .toList()
      ..sort((a, b) => a.startDate!.compareTo(b.startDate!));
    final undated = trips.where((t) => t.startDate == null);
    return [...dated, ...undated];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(myTripsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: tripsAsync.when(
        data: (trips) {
          final upcoming = _upcoming(trips);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Upcoming trips',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (upcoming.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Nothing coming up yet.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                )
              else
                for (final trip in upcoming) _UpcomingTripTile(trip: trip),
              const SizedBox(height: 16),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TripFormScreen()),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Create new trip'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Could not load trips: $error')),
      ),
    );
  }
}

class _UpcomingTripTile extends StatelessWidget {
  const _UpcomingTripTile({required this.trip});

  final Trip trip;

  String? _dateRange() {
    if (trip.startDate == null) return null;
    final start = trip.startDate!;
    final end = trip.endDate;
    String fmt(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return end == null ? fmt(start) : '${fmt(start)} – ${fmt(end)}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => TripFormScreen(trip: trip)),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
          title: Text(trip.name),
          subtitle: Text(_dateRange() ?? 'No dates set'),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}
