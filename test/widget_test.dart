// Basic smoke test: renders the sign-in screen without touching Firebase
// (full app startup needs a real/mocked Firebase.initializeApp, which is
// out of scope for this early scaffold).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tripthread/src/features/auth/presentation/sign_in_screen.dart';

void main() {
  testWidgets('SignInScreen shows email and password fields', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: SignInScreen()),
      ),
    );

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
