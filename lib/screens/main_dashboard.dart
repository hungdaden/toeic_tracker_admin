import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'exam_management_screen.dart';
import 'user_management_screen.dart';
import 'dashboard_overview_screen.dart';
import 'notification_management_screen.dart';
import 'question_bank_screen.dart';
import 'settings_screen.dart';
import 'auto_import_screen.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardOverviewScreen(),
    const ExamManagementScreen(),
    const QuestionBankScreen(),
    const UserManagementScreen(),
    const NotificationManagementScreen(),
    const AutoImportScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar Menu
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            backgroundColor: const Color(0xFF1E293B),
            indicatorColor: const Color(0xFF4F46E5),
            extended: MediaQuery.of(context).size.width > 1200,
            leading: Column(
              children: [
                const SizedBox(height: 20),
                Image.network(
                  'https://img.icons8.com/fluency/96/cat.png',
                  height: 50,
                ),
                const SizedBox(height: 10),
                if (MediaQuery.of(context).size.width > 1200)
                  const Text(
                    'TOEIC ADMIN',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                const SizedBox(height: 30),
              ],
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_rounded),
                label: Text('Tổng quan'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.assignment_rounded),
                label: Text('Quản lý đề thi'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.account_tree_rounded),
                label: Text('Ngân hàng câu hỏi'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_alt_rounded),
                label: Text('Người dùng'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.notifications_active_rounded),
                label: Text('Thông báo'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.auto_fix_high_rounded),
                label: Text('AI Auto Import'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_suggest_rounded),
                label: Text('Cài đặt'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1, color: Colors.white10),
          // Main Content Area
          Expanded(
            child: Container(
              color: const Color(0xFF0F172A),
              child: _screens[_selectedIndex],
            ),
          ),
        ],
      ),
    );
  }
}
