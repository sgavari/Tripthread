import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/trip_providers.dart';

class JoinTripScreen extends ConsumerStatefulWidget {
  const JoinTripScreen({super.key});

  @override
  ConsumerState<JoinTripScreen> createState() => _JoinTripScreenState();
}

class _JoinTripScreenState extends ConsumerState<JoinTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nicknameController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final nickname = _nicknameController.text.trim();
    await ref.read(tripControllerProvider.notifier).joinTripByCode(
          _codeController.text.trim(),
          nickname: nickname.isEmpty ? null : nickname,
        );

    final state = ref.read(tripControllerProvider);
    if (!mounted) return;
    if (state case AsyncError(:final error)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyError(error))),
      );
      return;
    }
    Navigator.of(context).pop();
  }

  String _friendlyError(Object error) {
    if (error is StateError) return error.message;
    return 'Could not join trip. Try again.';
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(tripControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Join a trip')),
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
                  Text(
                    'Enter the invite code someone shared with you.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(labelText: 'Invite code'),
                    validator: (value) => (value == null || value.trim().isEmpty)
                        ? 'Enter an invite code'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nicknameController,
                    decoration: const InputDecoration(
                      labelText: 'Your nickname for this trip (optional)',
                      hintText: 'e.g. Coach',
                    ),
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
                        : const Text('Join trip'),
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
