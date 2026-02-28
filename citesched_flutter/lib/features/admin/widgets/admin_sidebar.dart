import 'package:citesched_flutter/features/auth/providers/auth_provider.dart';
import 'package:citesched_flutter/features/auth/widgets/logout_confirmation_dialog.dart';
import 'package:citesched_flutter/core/theme/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminSidebar extends ConsumerWidget {
  final int selectedIndex;
  final Function(int) onDestinationSelected;

  const AdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Formal maroon theme color from design system
    final maroonColor = DesignSystem.headerColor;
    final innerMenuBg =
        Color.lerp(DesignSystem.headerColor, Colors.black, 0.15) ??
        DesignSystem.headerColor;

    return Container(
      width: 260, // var(--sidebar-width)
      color: maroonColor,
      child: Column(
        children: [
          // Header / Logo Area
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
            child: Column(
              children: [
                // Logo placeholder (using Icon as per previous implementation, but could be Image)
                // Logo
                Image.asset(
                  'assets/jmclogo.png',
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 12),
                Text(
                  'CITESched',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Inner Menu (Scrollable)
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: innerMenuBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView(
                padding: const EdgeInsets.all(15),
                children: [
                  _buildSectionHeader('MAIN MENU'),
                  _buildNavItem(0, Icons.dashboard_rounded, 'Dashboard'),

                  const SizedBox(height: 24),
                  _buildSectionHeader('OVERVIEW'),
                  _buildNavItem(
                    1,
                    Icons.person_add_alt_1_rounded,
                    'Adding Faculty',
                  ),
                  _buildNavItem(2, Icons.people_outline, 'Faculty Loading'),
                  _buildNavItem(3, Icons.menu_book_rounded, 'Subjects'),
                  _buildNavItem(4, Icons.meeting_room_outlined, 'Rooms'),
                  _buildNavItem(5, Icons.calendar_month_rounded, 'Timetable'),
                  _buildNavItem(6, Icons.warning_amber_rounded, 'Conflicts'),

                  const SizedBox(height: 24),
                  _buildSectionHeader('SYSTEM'),
                  _buildNavItem(7, Icons.assessment_outlined, 'Reports'),
                  const SizedBox(height: 12),
                  _buildNavItem(
                    9,
                    Icons.logout_rounded,
                    'Logout',
                    isLogout: true,
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => const LogoutConfirmationDialog(),
                      );
                      if (confirm == true) {
                        ref.read(authProvider.notifier).signOut();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          // Footer (User Info)
          Container(
            padding: const EdgeInsets.all(24),
            child: Consumer(
              builder: (context, ref, child) {
                final user = ref.watch(authProvider);
                final name = user?.userName ?? 'Admin User';
                // We don't have full_name yet, assuming userName is full name or fallback
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(color: Colors.white.withOpacity(0.2)),
                    const SizedBox(height: 16),
                    Text(
                      name, // {{ user.full_name|default:"Admin User" }}
                      style: GoogleFonts.openSans(
                        // using Segoe UI as per HTML
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'System Administrator',
                      style: GoogleFonts.openSans(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        title,
        style: GoogleFonts.openSans(
          fontSize: 11, // 0.7rem approx
          fontWeight: FontWeight.w600,
          color: Colors.white.withOpacity(0.5),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label, {
    bool isLogout = false,
    VoidCallback? onTap,
  }) {
    final isSelected = selectedIndex == index;
    // Hover/Active color: #8c0056 (var(--sidebar-hover))
    final hoverColor = const Color(0xFF8c0056);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () => onDestinationSelected(index),
        borderRadius: BorderRadius.circular(8),
        hoverColor: hoverColor,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      hoverColor,
                      hoverColor.withValues(alpha: 0.7),
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? const Border(
                    left: BorderSide(color: Colors.white, width: 3),
                  )
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isLogout
                    ? const Color(0xFFFFC107)
                    : Colors.white, // text-warning for logout
                size: 18,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.openSans(
                  color: isLogout ? const Color(0xFFFFC107) : Colors.white,
                  fontWeight: FontWeight.normal,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
