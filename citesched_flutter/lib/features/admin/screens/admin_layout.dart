import 'package:citesched_flutter/core/utils/responsive_helper.dart';
import 'package:citesched_flutter/core/theme/design_system.dart';
import 'package:citesched_flutter/features/admin/screens/admin_dashboard_screen.dart';
import 'package:citesched_flutter/features/admin/screens/faculty_management_screen.dart';
import 'package:citesched_flutter/features/admin/screens/faculty_loading_screen.dart';
import 'package:citesched_flutter/features/admin/screens/subject_management_screen.dart';
import 'package:citesched_flutter/features/admin/screens/room_management_screen.dart';
import 'package:citesched_flutter/features/admin/screens/timetable_screen.dart';
import 'package:citesched_flutter/features/admin/screens/conflict_screen.dart';
import 'package:citesched_flutter/features/admin/screens/report_screen.dart';
import 'package:citesched_flutter/features/admin/widgets/admin_sidebar.dart';
import 'package:citesched_flutter/core/widgets/app_header.dart';
import 'package:citesched_flutter/core/widgets/draggable_fab.dart';
import 'package:citesched_flutter/core/widgets/nlp_query_dialog.dart';
import 'package:flutter/material.dart';

class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const AdminDashboardScreen(),
    const FacultyManagementScreen(),
    const FacultyLoadingScreen(),
    const SubjectManagementScreen(),
    const RoomManagementScreen(),
    const TimetableScreen(),
    const ConflictScreen(),
    const ReportScreen(),
  ];

  final List<String> _titles = [
    'Dashboard',
    'Faculty Management',
    'Faculty Loading',
    'Subject Management',
    'Room Management',
    'Timetable',
    'Conflicts',
    'Reports',
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveHelper.isDesktop(context);

    final scaffold = Scaffold(
      backgroundColor: DesignSystem.backgroundColor,
      appBar: !isDesktop
          ? AppHeader(
              title: _titles[_selectedIndex],
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  tooltip: 'Open menu',
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
            )
          : null,
      drawer: !isDesktop
          ? Drawer(
              width: 260,
              backgroundColor: DesignSystem.headerColor,
              child: AdminSidebar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                  Navigator.pop(context);
                },
              ),
            )
          : null,
      body: Row(
        children: [
          if (isDesktop)
            AdminSidebar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
            ),
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
    );

    return Stack(
      children: [
        scaffold,
        DraggableFab(
          child: FloatingActionButton.extended(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const NLPQueryDialog(),
              );
            },
            backgroundColor: const Color(0xFF4f003b),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Ask Me!'),
            tooltip: 'Hey ask me some questions!',
          ),
        ),
      ],
    );
  }
}
