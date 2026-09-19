import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/color_utils.dart';
import '../../auth/application/auth_providers.dart';
import '../../trips/application/trip_providers.dart';
import '../../trips/domain/trip.dart';
import '../application/chat_providers.dart';
import '../domain/chat_message.dart';
import 'chat_screen.dart';

/// A WhatsApp-style list of every trip you're in, each row showing a live
/// preview of its latest message. Tapping a row opens that trip's chat.
class ChatsListScreen extends ConsumerWidget {
  const ChatsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(myTripsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: tripsAsync.when(
        data: (trips) => trips.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Join or create a trip to start chatting.',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ListView.separated(
                itemCount: trips.length,
                separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
                itemBuilder: (context, index) => _ChatListTile(trip: trips[index]),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Could not load chats: $error')),
      ),
    );
  }
}

class _ChatListTile extends ConsumerWidget {
  const _ChatListTile({required this.trip});

  final Trip trip;

  String _preview(ChatMessage message, String? currentUserId) {
    final prefix = message.senderId == currentUserId ? 'You: ' : '';
    return '$prefix${message.text}';
  }

  String _timeLabel(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final sameDay =
        time.year == now.year && time.month == now.month && time.day == now.day;
    if (sameDay) {
      final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
      final minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute ${time.hour >= 12 ? 'PM' : 'AM'}';
    }
    return '${time.month}/${time.day}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latestAsync = ref.watch(tripLatestMessageProvider(trip.id));
    final currentUserId = ref.watch(firebaseAuthProvider).currentUser?.uid;

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
      subtitle: latestAsync.when(
        data: (message) => Text(
          message == null ? 'No messages yet' : _preview(message, currentUserId),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        loading: () => const Text('…'),
        error: (_, _) => const SizedBox.shrink(),
      ),
      trailing: latestAsync.maybeWhen(
        data: (message) =>
            message == null ? null : Text(_timeLabel(message.createdAt)),
        orElse: () => null,
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(tripId: trip.id, tripName: trip.name),
        ),
      ),
    );
  }
}
