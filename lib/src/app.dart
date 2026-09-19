import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/navigation.dart';
import 'features/auth/application/auth_providers.dart';
import 'features/auth/presentation/sign_in_screen.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/notifications/application/push_notification_service.dart';

/// Root widget. Wires up theming and delegates routing to [AuthGate].
class TripThreadApp extends StatelessWidget {
  const TripThreadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TripThread',
      debugShowCheckedModeBanner: false,
      navigatorKey: rootNavigatorKey,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3E7FA6), // soft ocean blue
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3E7FA6),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

/// Watches auth state and shows the signed-in or signed-out flow accordingly.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);
    // Keeps users/{uid} in sync for every active session, not just fresh
    // sign-ins — activated by watching it here, result unused.
    ref.watch(syncOwnUserProfileProvider);
    // Requests notification permission and registers this device's FCM
    // token — same "activated by watching" pattern.
    ref.watch(registerPushNotificationsProvider);

    return authState.when(
      data: (user) =>
          user == null ? const SignInScreen() : const HomeScreen(),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Something went wrong: $error')),
      ),
    );
  }
}
