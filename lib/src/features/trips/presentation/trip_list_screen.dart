import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/color_utils.dart';
import '../../auth/application/auth_providers.dart';
import '../../chat/presentation/chat_screen.dart';
import '../application/trip_providers.dart';
import '../domain/trip.dart';
import 'join_trip_screen.dart';
import 'trip_form_screen.dart';

enum _AccountAction { signOut, deleteAccount }

Future<void> _confirmAndDeleteAccount(BuildContext context, WidgetRef ref) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete account?'),
      content: const Text(
        'This permanently deletes your account and removes you from every '
        "trip. Messages and expenses you've already added stay visible to "
        "your trip-mates, same as leaving a group chat elsewhere. This can't "
        'be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton.tonal(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;

  await ref.read(authControllerProvider.notifier).deleteAccount();
  final state = ref.read(authControllerProvider);
  if (!context.mounted) return;

  if (state case AsyncError(:final error)) {
    if (error is FirebaseAuthException && error.code == 'requires-recent-login') {
      await ref.read(authControllerProvider.notifier).signOut();
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Please sign in again'),
          content: const Text(
            "For your security, deleting an account requires a recent sign-in. "
            "You've been signed out — sign back in and try deleting again "
            'right away.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not delete account. Try again.')),
    );
  }
}

class TripListScreen extends ConsumerWidget {
  const TripListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(myTripsProvider);
    // The empty state has its own prominent "Start your first trip" CTA —
    // showing the FAB too would be a redundant second call to action.
    final hasTrips =
        tripsAsync.maybeWhen(data: (trips) => trips.isNotEmpty, orElse: () => false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your trips'),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add_outlined),
            tooltip: 'Join a trip',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const JoinTripScreen()),
            ),
          ),
          PopupMenuButton<_AccountAction>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Account',
            onSelected: (action) async {
              switch (action) {
                case _AccountAction.signOut:
                  await ref.read(authControllerProvider.notifier).signOut();
                case _AccountAction.deleteAccount:
                  await _confirmAndDeleteAccount(context, ref);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _AccountAction.signOut,
                child: Text('Sign out'),
              ),
              PopupMenuItem(
                value: _AccountAction.deleteAccount,
                child: Text('Delete account'),
              ),
            ],
          ),
        ],
      ),
      body: tripsAsync.when(
        data: (trips) => trips.isEmpty
            ? const _EmptyState()
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: trips.length,
                itemBuilder: (context, index) => _TripCard(trip: trips[index]),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Could not load trips: $error')),
      ),
      floatingActionButton: hasTrips
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TripFormScreen()),
              ),
              icon: const Icon(Icons.add),
              label: const Text('New trip'),
            )
          : null,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        children: [
          _HeroIllustration(colorScheme: colorScheme),
          const SizedBox(height: 28),
          Text(
            'Your trips live here',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Plan together and chat in real time — all in one place.',
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TripFormScreen()),
            ),
            child: const Text('Start your first trip'),
          ),
          const SizedBox(height: 32),
          Row(
            children: const [
              Expanded(
                child: _FeatureHighlight(
                  icon: Icons.map_outlined,
                  label: 'Plan trips',
                  description: 'Set dates & destination — we add a photo',
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _FeatureHighlight(
                  icon: Icons.chat_bubble_outline,
                  label: 'Group chat',
                  description: 'Real-time, right inside the trip',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroIllustration extends StatelessWidget {
  const _HeroIllustration({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer,
            Color.lerp(colorScheme.primaryContainer, colorScheme.tertiaryContainer, 0.6)!,
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 28,
            top: 28,
            child: _FloatingIcon(icon: Icons.card_travel, colorScheme: colorScheme),
          ),
          Positioned(
            right: 32,
            top: 20,
            child: _FloatingIcon(icon: Icons.chat_bubble, colorScheme: colorScheme, small: true),
          ),
          Positioned(
            right: 28,
            bottom: 24,
            child: _FloatingIcon(icon: Icons.group, colorScheme: colorScheme),
          ),
          Icon(Icons.travel_explore, size: 72, color: colorScheme.onPrimaryContainer),
        ],
      ),
    );
  }
}

class _FloatingIcon extends StatelessWidget {
  const _FloatingIcon({
    required this.icon,
    required this.colorScheme,
    this.small = false,
  });

  final IconData icon;
  final ColorScheme colorScheme;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final size = small ? 36.0 : 44.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, size: small ? 18 : 22, color: colorScheme.primary),
    );
  }
}

class _FeatureHighlight extends StatelessWidget {
  const _FeatureHighlight({
    required this.icon,
    required this.label,
    required this.description,
  });

  final IconData icon;
  final String label;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: colorScheme.onSecondaryContainer),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip});

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
    final dateRange = _dateRange();
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => TripFormScreen(trip: trip)),
        ),
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _TripImage(tripId: trip.id, imageUrl: trip.imageUrl),
              // Scrim so the white text stays legible over any photo.
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xCC000000)],
                    stops: [0.45, 1.0],
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: _ScrimIconButton(
                  icon: Icons.chat_bubble_outline,
                  tooltip: 'Open chat',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          ChatScreen(tripId: trip.id, tripName: trip.name),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      trip.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (trip.destination != null)
                      Text(
                        trip.destination!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      dateRange ?? '${trip.memberIds.length} member(s)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScrimIconButton extends StatelessWidget {
  const _ScrimIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}

class _TripImage extends StatelessWidget {
  const _TripImage({required this.tripId, required this.imageUrl});

  final String tripId;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (imageUrl == null) {
      final accent = colorForKey(tripId);
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.lerp(accent, Colors.white, 0.15)!, accent],
          ),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.landscape_outlined,
          size: 56,
          color: Colors.white,
        ),
      );
    }
    return Image.network(
      imageUrl!,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: colorScheme.surfaceContainerHighest,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(strokeWidth: 2),
        );
      },
      errorBuilder: (context, error, stackTrace) => Container(
        color: colorScheme.secondaryContainer,
        alignment: Alignment.center,
        child: Icon(
          Icons.broken_image_outlined,
          size: 56,
          color: colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}
