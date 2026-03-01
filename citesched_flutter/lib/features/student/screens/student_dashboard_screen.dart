import 'package:citesched_client/citesched_client.dart';
import 'package:citesched_flutter/main.dart';
import 'package:citesched_flutter/core/providers/schedule_sync_provider.dart';
import 'package:citesched_flutter/core/utils/responsive_helper.dart';
import 'package:citesched_flutter/core/utils/schedule_export_service.dart';
import 'package:citesched_flutter/features/auth/providers/auth_provider.dart';
import 'package:citesched_flutter/features/auth/widgets/logout_confirmation_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:citesched_flutter/features/admin/widgets/weekly_calendar_view.dart';

final myProfileProvider = FutureProvider<Student?>((ref) async {
  return await client.student.getMyProfile();
});

final myScheduleProvider = FutureProvider<List<ScheduleInfo>>((ref) async {
  ref.watch(scheduleSyncTriggerProvider);
  return await client.timetable.getPersonalSchedule();
});

class StudentDashboardScreen extends ConsumerWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(myScheduleProvider);
    final profileAsync = ref.watch(myProfileProvider);
    final user = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final maroonColor = const Color(0xFF720045);
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8F9FA);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Student Dashboard',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: maroonColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: ResponsiveHelper.maxContentWidth(context),
              ),
              child: SingleChildScrollView(
                padding: ResponsiveHelper.pagePadding(context),
                child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Premium Welcome Card
            Container(
              padding: EdgeInsets.all(
                ResponsiveHelper.isMobile(context) ? 16 : 32,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [maroonColor, const Color(0xFF8e005b)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: maroonColor.withOpacity(0.3),
                    blurRadius: 25,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white.withOpacity(0.15),
                      child: Text(
                        (profileAsync.value?.name.isNotEmpty == true
                                ? profileAsync.value!.name[0]
                                : user?.userName?[0] ?? 'S')
                            .toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back, Student!',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profileAsync.value?.name ??
                              user?.userName ??
                              'Student',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => const LogoutConfirmationDialog(),
                      );
                      if (confirm == true) {
                        ref.read(authProvider.notifier).signOut();
                      }
                    },
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: Text(
                      'Sign Out',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: Colors.white30),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
              ),

            const SizedBox(height: 32),

            Text(
              'Student Profile',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            profileAsync.when(
              loading: () => Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const LinearProgressIndicator(minHeight: 6),
              ),
              error: (err, _) => Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text('Could not load profile: $err'),
              ),
              data: (profile) {
                if (profile == null) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text('Profile not found for this account.'),
                  );
                }
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      maroonColor.withOpacity(0.08),
                    ),
                    columnSpacing: 16,
                    columns: [
                      _tableHeader('STUDENT ID'),
                      _tableHeader('NAME'),
                      _tableHeader('PROGRAM'),
                      _tableHeader('SECTION'),
                      _tableHeader('YEAR LEVEL'),
                    ],
                    rows: [
                      DataRow(
                        cells: [
                          DataCell(Text(profile.studentNumber)),
                          DataCell(Text(profile.name)),
                          DataCell(Text(profile.course)),
                          DataCell(Text(profile.section ?? 'Unassigned')),
                          DataCell(Text('${profile.yearLevel}')),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            Text(
              'My Class Schedule',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            scheduleAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (schedules) {
                if (schedules.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(40),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No classes found for your section.',
                          style: GoogleFonts.poppins(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Sort schedules by day then start time for consistent render
                schedules.sort((a, b) {
                  final ta = a.schedule.timeslot;
                  final tb = b.schedule.timeslot;
                  if (ta == null || tb == null) return 0;
                  final dayOrder = ta.day.index.compareTo(tb.day.index);
                  if (dayOrder != 0) return dayOrder;
                  return ta.startTime.compareTo(tb.startTime);
                });

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            await ScheduleExportService.exportStudentSchedulePdf(
                              student: profileAsync.value,
                              schedules: schedules,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: maroonColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                          icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                          label: const Text('Export PDF'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final result =
                                await ScheduleExportService.exportStudentScheduleDocx(
                                  student: profileAsync.value,
                                  schedules: schedules,
                                );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  result != null
                                      ? 'DOCX exported: $result'
                                      : 'DOCX export canceled.',
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                          icon: const Icon(Icons.description_rounded, size: 18),
                          label: const Text('Export DOCX'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: ResponsiveHelper.calendarHeight(context),
                      child: WeeklyCalendarView(
                        schedules: schedules,
                        maroonColor: maroonColor,
                        isStudentView: true,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Subjects (read-only)',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: schedules.length,
                        separatorBuilder: (_, __) => const Divider(height: 12),
                        itemBuilder: (context, index) {
                          final info = schedules[index];
                          final sched = info.schedule;
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 4,
                            ),
                            title: Text(
                              sched.subject?.name ?? 'Subject',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${sched.section} • ${sched.room?.name ?? 'Room TBD'}',
                              style: GoogleFonts.poppins(fontSize: 13),
                            ),
                            trailing: Text(
                              sched.faculty?.name ?? 'Faculty',
                              style: GoogleFonts.poppins(fontSize: 13),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

Widget _infoRow(String label, String value) {
  return Row(
    children: [
      SizedBox(
        width: 110,
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: GoogleFonts.poppins(fontSize: 13),
        ),
      ),
    ],
  );
}

DataColumn _tableHeader(String title) {
  return DataColumn(
    label: Text(
      title,
      style: GoogleFonts.poppins(
        fontWeight: FontWeight.w700,
        fontSize: 12,
        letterSpacing: 0.4,
      ),
    ),
  );
}
