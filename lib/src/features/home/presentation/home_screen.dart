import 'package:flutter/material.dart';

import '../../chat/presentation/chats_list_screen.dart';
import '../../expenses/presentation/expenses_list_screen.dart';
import '../../trips/presentation/trip_list_screen.dart';
import 'home_overview_screen.dart';

/// Root shell once signed in: a small bottom nav switching between a Home
/// dashboard (upcoming trips + create action), the full trip list,
/// expense splitting, and an aggregated chat list. Each tab keeps its own
/// AppBar — nested Scaffolds are the normal Flutter pattern for this.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const _tabs = [
    HomeOverviewScreen(),
    TripListScreen(),
    ExpensesListScreen(),
    ChatsListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.card_travel_outlined),
            selectedIcon: Icon(Icons.card_travel),
            label: 'Trips',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Expenses',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chats',
          ),
        ],
      ),
    );
  }
}
