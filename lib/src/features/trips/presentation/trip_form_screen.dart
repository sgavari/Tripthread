import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/color_utils.dart';
import '../../auth/application/auth_providers.dart';
import '../../chat/presentation/chat_screen.dart';
import '../../users/application/user_providers.dart';
import '../application/trip_providers.dart';
import '../domain/trip.dart';

/// Create-trip form when [trip] is null, edit-trip form when it isn't.
class TripFormScreen extends ConsumerStatefulWidget {
  const TripFormScreen({super.key, this.trip});

  final Trip? trip;

  bool get isEditing => trip != null;

  @override
  ConsumerState<TripFormScreen> createState() => _TripFormScreenState();
}

class _TripFormScreenState extends ConsumerState<TripFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController =
      TextEditingController(text: widget.trip?.name ?? '');
  late final _destinationController =
      TextEditingController(text: widget.trip?.destination ?? '');
  final _nicknameController = TextEditingController();
  late DateTime? _startDate = widget.trip?.startDate;
  late DateTime? _endDate = widget.trip?.endDate;

  @override
  void dispose() {
    _nameController.dispose();
    _destinationController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = (isStart ? _startDate : _endDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();
    final destinationText = _destinationController.text.trim();
    final destination = destinationText.isEmpty ? null : destinationText;

    final trip = widget.trip;
    if (trip == null) {
      final nickname = _nicknameController.text.trim();
      await ref.read(tripControllerProvider.notifier).createTrip(
            name: name,
            destination: destination,
            startDate: _startDate,
            endDate: _endDate,
            nickname: nickname.isEmpty ? null : nickname,
          );
    } else {
      await ref.read(tripControllerProvider.notifier).updateTrip(
            tripId: trip.id,
            name: name,
            destination: destination,
            previousDestination: trip.destination,
            previousImageUrl: trip.imageUrl,
            startDate: _startDate,
            endDate: _endDate,
          );
    }

    final state = ref.read(tripControllerProvider);
    if (!mounted) return;
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? 'Could not save changes. Try again.'
                : 'Could not create trip. Try again.',
          ),
        ),
      );
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final trip = widget.trip;
    if (trip == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete trip?'),
        content: Text('"${trip.name}" will be permanently deleted.'),
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

    await ref.read(tripControllerProvider.notifier).deleteTrip(trip.id);
    final state = ref.read(tripControllerProvider);
    if (!mounted) return;
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete trip. Try again.')),
      );
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _leave() async {
    final trip = widget.trip;
    if (trip == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave trip?'),
        content: Text('You\'ll need a new invite to rejoin "${trip.name}".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(tripControllerProvider.notifier).leaveTrip(trip.id);
    final state = ref.read(tripControllerProvider);
    if (!mounted) return;
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not leave trip. Try again.')),
      );
      return;
    }
    Navigator.of(context).pop();
  }

  void _shareInvite() {
    final trip = widget.trip;
    if (trip?.inviteCode == null) return;
    SharePlus.instance.share(
      ShareParams(
        text: 'Join my trip "${trip!.name}" on TripThread!\n'
            'Invite code: ${trip.inviteCode}',
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not set';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(tripControllerProvider).isLoading;
    final currentUserId = ref.watch(firebaseAuthProvider).currentUser?.uid;
    final canDelete =
        widget.isEditing && widget.trip!.creatorId == currentUserId;
    final canLeave = widget.isEditing &&
        widget.trip!.creatorId != currentUserId &&
        widget.trip!.memberIds.contains(currentUserId);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit trip' : 'New trip'),
        actions: [
          if (widget.isEditing)
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline),
              tooltip: 'Open chat',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    tripId: widget.trip!.id,
                    tripName: widget.trip!.name,
                  ),
                ),
              ),
            ),
          if (widget.isEditing && widget.trip!.inviteCode != null)
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'Share invite',
              onPressed: _shareInvite,
            ),
          if (canDelete)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete trip',
              onPressed: isLoading ? null : _delete,
            ),
          if (canLeave)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Leave trip',
              onPressed: isLoading ? null : _leave,
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.isEditing && widget.trip!.inviteCode != null) ...[
                    Text(
                      'Invite code: ${widget.trip!.inviteCode}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Trip name'),
                    validator: (value) => (value == null || value.trim().isEmpty)
                        ? 'Give your trip a name'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _destinationController,
                    decoration: const InputDecoration(
                      labelText: 'Destination (optional)',
                      hintText: 'e.g. Lisbon, Portugal',
                    ),
                  ),
                  if (!widget.isEditing) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nicknameController,
                      decoration: const InputDecoration(
                        labelText: 'Your nickname for this trip (optional)',
                        hintText: 'e.g. Coach',
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Start date'),
                    subtitle: Text(_formatDate(_startDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _pickDate(isStart: true),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('End date'),
                    subtitle: Text(_formatDate(_endDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _pickDate(isStart: false),
                  ),
                  if (widget.isEditing) ...[
                    const SizedBox(height: 16),
                    _MembersList(
                      tripId: widget.trip!.id,
                      memberIds: widget.trip!.memberIds,
                      creatorId: widget.trip!.creatorId,
                      canManageMembers: widget.trip!.creatorId == currentUserId,
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: isLoading ? null : _submit,
                    child: isLoading
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(widget.isEditing ? 'Save changes' : 'Create trip'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MembersList extends ConsumerWidget {
  const _MembersList({
    required this.tripId,
    required this.memberIds,
    required this.creatorId,
    required this.canManageMembers,
  });

  final String tripId;
  final List<String> memberIds;
  final String creatorId;
  final bool canManageMembers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Members', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        for (final uid in memberIds)
          _MemberTile(
            tripId: tripId,
            uid: uid,
            // The creator manages the roster but can't remove themselves
            // here — that's what deleting the trip is for.
            canRemove: canManageMembers && uid != creatorId,
          ),
      ],
    );
  }
}

class _MemberTile extends ConsumerWidget {
  const _MemberTile({
    required this.tripId,
    required this.uid,
    required this.canRemove,
  });

  final String tripId;
  final String uid;
  final bool canRemove;

  Future<void> _confirmRemove(BuildContext context, WidgetRef ref, String label) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove member?'),
        content: Text('$label will be removed from this trip.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(tripControllerProvider.notifier).removeMember(tripId, uid);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider(uid));
    final nicknameAsync = ref.watch(tripMemberNicknameProvider(tripId, uid));

    return profileAsync.when(
      data: (profile) {
        // Nickname (this trip only) takes priority over the account-wide
        // name; while it's still loading, fall back rather than block on it.
        final label =
            nicknameAsync.value ?? profile?.label ?? uid;
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: profile?.photoUrl == null ? colorForKey(uid) : null,
            backgroundImage: profile?.photoUrl != null
                ? NetworkImage(profile!.photoUrl!)
                : null,
            child: profile?.photoUrl == null
                ? Text(
                    label.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  )
                : null,
          ),
          title: Text(label),
          subtitle: nicknameAsync.value != null && profile?.label != null
              ? Text(profile!.label)
              : null,
          trailing: canRemove
              ? IconButton(
                  icon: const Icon(Icons.person_remove_outlined),
                  tooltip: 'Remove member',
                  onPressed: () => _confirmRemove(context, ref, label),
                )
              : null,
        );
      },
      loading: () => const ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(child: SizedBox.shrink()),
        title: Text('Loading…'),
      ),
      error: (_, _) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const CircleAvatar(child: Icon(Icons.person_outline)),
        title: Text(uid),
      ),
    );
  }
}
