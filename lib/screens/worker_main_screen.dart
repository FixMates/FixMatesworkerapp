import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'worker_dashboard_screen.dart';
import 'worker_leads_screen.dart';
import 'worker_profile_screen.dart';

class WorkerMainScreen extends StatefulWidget {
  const WorkerMainScreen({super.key});

  @override
  State<WorkerMainScreen> createState() => _WorkerMainScreenState();
}

class _WorkerMainScreenState extends State<WorkerMainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      WorkerDashboardScreen(
        onOpenLeads: () => setState(() => _currentIndex = 1),
        onOpenProfile: () => setState(() => _currentIndex = 2),
      ),
      WorkerLeadsScreen(
        onOpenProfile: () => setState(() => _currentIndex = 2),
      ),
      const WorkerProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: AppTheme.border, width: 1)),
        ),
        height: 64,
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedFontSize: 12,
          unselectedFontSize: 12,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment),
              label: 'Leads',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}