import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../../trips/application/trip_providers.dart';
import '../../users/application/user_providers.dart';
import '../application/expense_providers.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key, required this.tripId});

  final String tripId;

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  String? _paidByUid;
  Set<String> _splitAmongUids = {};
  bool _initializedSelection = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _initSelectionIfNeeded(List<String> memberIds) {
    if (_initializedSelection) return;
    _initializedSelection = true;
    final currentUserId = ref.read(firebaseAuthProvider).currentUser?.uid;
    _paidByUid = currentUserId ?? (memberIds.isNotEmpty ? memberIds.first : null);
    _splitAmongUids = memberIds.toSet();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_paidByUid == null || _splitAmongUids.isEmpty) return;
    final amount = double.parse(_amountController.text.trim());

    await ref.read(expenseControllerProvider.notifier).addExpense(
          tripId: widget.tripId,
          description: _descriptionController.text.trim(),
          amount: amount,
          paidByUid: _paidByUid!,
          splitAmongUids: _splitAmongUids.toList(),
        );

    final state = ref.read(expenseControllerProvider);
    if (!mounted) return;
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not add expense. Try again.')),
      );
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final tripsAsync = ref.watch(myTripsProvider);
    final isLoading = ref.watch(expenseControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Add expense')),
      body: tripsAsync.when(
        data: (trips) {
          final trip = trips.where((t) => t.id == widget.tripId).firstOrNull;
          if (trip == null) {
            return const Center(child: Text('Trip not found.'));
          }
          _initSelectionIfNeeded(trip.memberIds);

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'What was it for?'),
                      validator: (value) => (value == null || value.trim().isEmpty)
                          ? 'Enter a description'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Amount', prefixText: '\$ '),
                      validator: (value) {
                        final parsed = double.tryParse((value ?? '').trim());
                        if (parsed == null || parsed <= 0) return 'Enter a valid amount';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Text('Paid by', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    for (final uid in trip.memberIds)
                      _PaidByOption(
                        tripId: widget.tripId,
                        uid: uid,
                        selected: _paidByUid == uid,
                        onTap: () => setState(() => _paidByUid = uid),
                      ),
                    const SizedBox(height: 20),
                    Text('Split among', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    for (final uid in trip.memberIds)
                      _SplitOption(
                        tripId: widget.tripId,
                        uid: uid,
                        selected: _splitAmongUids.contains(uid),
                        onChanged: (checked) => setState(() {
                          if (checked) {
                            _splitAmongUids.add(uid);
                          } else {
                            _splitAmongUids.remove(uid);
                          }
                        }),
                      ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: isLoading ? null : _submit,
                      child: isLoading
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Add expense'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Could not load trip: $error')),
      ),
    );
  }
}

class _PaidByOption extends ConsumerWidget {
  const _PaidByOption({
    required this.tripId,
    required this.uid,
    required this.selected,
    required this.onTap,
  });

  final String tripId;
  final String uid;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nickname = ref.watch(tripMemberNicknameProvider(tripId, uid)).value;
    final profile = ref.watch(userProfileProvider(uid)).value;
    final label = nickname ?? profile?.label ?? uid;

    return RadioListTile<String>(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(label),
      value: uid,
      groupValue: selected ? uid : null,
      onChanged: (_) => onTap(),
    );
  }
}

class _SplitOption extends ConsumerWidget {
  const _SplitOption({
    required this.tripId,
    required this.uid,
    required this.selected,
    required this.onChanged,
  });

  final String tripId;
  final String uid;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nickname = ref.watch(tripMemberNicknameProvider(tripId, uid)).value;
    final profile = ref.watch(userProfileProvider(uid)).value;
    final label = nickname ?? profile?.label ?? uid;

    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(label),
      value: selected,
      onChanged: (checked) => onChanged(checked ?? false),
    );
  }
}
