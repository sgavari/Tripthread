import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../../trips/application/trip_providers.dart';
import '../../users/application/user_providers.dart';
import '../application/chat_providers.dart';
import '../domain/chat_message.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.tripId, required this.tripName});

  final String tripId;
  final String tripName;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _textController.text;
    if (text.trim().isEmpty) return;
    _textController.clear();
    await ref
        .read(chatControllerProvider.notifier)
        .sendMessage(widget.tripId, text);

    final state = ref.read(chatControllerProvider);
    if (!mounted) return;
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not send. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(tripMessagesProvider(widget.tripId));
    final currentUserId = ref.watch(firebaseAuthProvider).currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: Text(widget.tripName)),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) => messages.isEmpty
                  ? Center(
                      child: Text(
                        'No messages yet. Say hi!',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    )
                  : ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        return _MessageBubble(
                          tripId: widget.tripId,
                          message: message,
                          isOwn: message.senderId == currentUserId,
                        );
                      },
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) =>
                  Center(child: Text('Could not load chat: $error')),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Message',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(24)),
                        ),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    icon: const Icon(Icons.send),
                    onPressed: _send,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends ConsumerWidget {
  const _MessageBubble({
    required this.tripId,
    required this.message,
    required this.isOwn,
  });

  final String tripId;
  final ChatMessage message;
  final bool isOwn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: GestureDetector(
          // Own messages aren't reportable — nothing to flag to yourself.
          onLongPress: isOwn ? null : () => _showReportSheet(context, ref),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isOwn ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isOwn)
                  _SenderLabel(tripId: tripId, senderId: message.senderId),
                Text(message.text),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showReportSheet(BuildContext context, WidgetRef ref) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => SafeArea(
        child: ListTile(
          leading: const Icon(Icons.flag_outlined),
          title: const Text('Report this message'),
          subtitle: const Text("We'll review it — this doesn't notify the sender."),
          onTap: () => Navigator.of(context).pop(true),
        ),
      ),
    );
    if (confirmed != true) return;

    await ref.read(chatControllerProvider.notifier).reportMessage(
          tripId: tripId,
          messageId: message.id,
          reportedUid: message.senderId,
          text: message.text,
        );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message reported. Thanks for letting us know.')),
    );
  }
}

class _SenderLabel extends ConsumerWidget {
  const _SenderLabel({required this.tripId, required this.senderId});

  final String tripId;
  final String senderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nickname = ref.watch(tripMemberNicknameProvider(tripId, senderId)).value;
    final profile = ref.watch(userProfileProvider(senderId)).value;
    final label = nickname ?? profile?.label ?? senderId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}
