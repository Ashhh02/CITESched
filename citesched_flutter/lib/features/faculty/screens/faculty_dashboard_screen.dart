import 'package:citesched_client/citesched_client.dart';
import 'package:citesched_flutter/main.dart';
import 'package:citesched_flutter/core/providers/schedule_sync_provider.dart';
import 'package:citesched_flutter/features/auth/providers/auth_provider.dart';
import 'package:citesched_flutter/features/auth/widgets/logout_confirmation_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:citesched_flutter/features/admin/widgets/weekly_calendar_view.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

final facultyScheduleProvider = FutureProvider<List<ScheduleInfo>>((ref) async {
  ref.watch(scheduleSyncTriggerProvider);
  return await client.timetable.getPersonalSchedule();
});

final facultyAvailabilityProvider = FutureProvider<List<FacultyAvailability>>((
  ref,
) async {
  ref.watch(scheduleSyncTriggerProvider);
  try {
    final myFaculty = await client.faculty.getMyProfile();
    if (myFaculty?.id == null) return [];
    return await client.admin.getFacultyAvailability(myFaculty!.id!);
  } catch (e) {
    return [];
  }
});

class FacultyDashboardScreen extends ConsumerStatefulWidget {
  const FacultyDashboardScreen({super.key});

  @override
  ConsumerState<FacultyDashboardScreen> createState() =>
      _FacultyDashboardScreenState();
}

class _FacultyDashboardScreenState extends ConsumerState<FacultyDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  final Color maroonColor = const Color(0xFF720045);

  String _getDayName(DayOfWeek? day) {
    switch (day) {
      case DayOfWeek.mon:
        return 'Monday';
      case DayOfWeek.tue:
        return 'Tuesday';
      case DayOfWeek.wed:
        return 'Wednesday';
      case DayOfWeek.thu:
        return 'Thursday';
      case DayOfWeek.fri:
        return 'Friday';
      case DayOfWeek.sat:
        return 'Saturday';
      case DayOfWeek.sun:
        return 'Sunday';
      default:
        return '—';
    }
  }

  int _parseTimeToMinutes(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return 0;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return hour * 60 + minute;
  }

  bool _isWithinPreferredAvailability(
    Schedule schedule,
    List<FacultyAvailability> availabilities,
  ) {
    final timeslot = schedule.timeslot;
    if (timeslot == null) return true;
    final preferred = availabilities.where((a) => a.isPreferred).toList();
    if (preferred.isEmpty) return true;

    final tsStart = _parseTimeToMinutes(timeslot.startTime);
    final tsEnd = _parseTimeToMinutes(timeslot.endTime);
    for (final a in preferred) {
      if (a.dayOfWeek != timeslot.day) continue;
      final aStart = _parseTimeToMinutes(a.startTime);
      final aEnd = _parseTimeToMinutes(a.endTime);
      if (tsStart >= aStart && tsEnd <= aEnd) return true;
    }
    return false;
  }

  double _computeAssignedHours(List<ScheduleInfo> schedules) {
    double totalMinutes = 0;
    for (final info in schedules) {
      final ts = info.schedule.timeslot;
      if (ts == null) continue;
      final start = _parseTimeToMinutes(ts.startTime);
      final end = _parseTimeToMinutes(ts.endTime);
      if (end > start) totalMinutes += (end - start);
    }
    return totalMinutes / 60.0;
  }

  double _computePreferredHours(List<FacultyAvailability> availabilities) {
    double totalMinutes = 0;
    for (final a in availabilities.where((a) => a.isPreferred)) {
      final start = _parseTimeToMinutes(a.startTime);
      final end = _parseTimeToMinutes(a.endTime);
      if (end > start) totalMinutes += (end - start);
    }
    return totalMinutes / 60.0;
  }

  double _computeAssignedHoursWithinPreferred(
    List<ScheduleInfo> schedules,
    List<FacultyAvailability> availabilities,
  ) {
    final preferred = availabilities.where((a) => a.isPreferred).toList();
    double overlapMinutes = 0;

    for (final info in schedules) {
      final ts = info.schedule.timeslot;
      if (ts == null) continue;
      final tsStart = _parseTimeToMinutes(ts.startTime);
      final tsEnd = _parseTimeToMinutes(ts.endTime);

      for (final a in preferred) {
        if (a.dayOfWeek != ts.day) continue;
        final aStart = _parseTimeToMinutes(a.startTime);
        final aEnd = _parseTimeToMinutes(a.endTime);
        final overlapStart = tsStart > aStart ? tsStart : aStart;
        final overlapEnd = tsEnd < aEnd ? tsEnd : aEnd;
        if (overlapEnd > overlapStart) {
          overlapMinutes += (overlapEnd - overlapStart);
        }
      }
    }

    return overlapMinutes / 60.0;
  }

  List<String> _computeFreeSlotLabels(
    List<ScheduleInfo> schedules,
    List<FacultyAvailability> availabilities,
  ) {
    final preferred = availabilities.where((a) => a.isPreferred).toList();
    if (preferred.isEmpty) return const [];

    final assignedByDay = <DayOfWeek, List<_MinuteRange>>{};
    for (final info in schedules) {
      final ts = info.schedule.timeslot;
      if (ts == null) continue;
      final start = _parseTimeToMinutes(ts.startTime);
      final end = _parseTimeToMinutes(ts.endTime);
      assignedByDay.putIfAbsent(ts.day, () => []).add(_MinuteRange(start, end));
    }

    for (final entry in assignedByDay.entries) {
      entry.value.sort((a, b) => a.start.compareTo(b.start));
    }

    final freeSlots = <String>[];
    for (final a in preferred) {
      final window = _MinuteRange(
        _parseTimeToMinutes(a.startTime),
        _parseTimeToMinutes(a.endTime),
      );

      var segments = <_MinuteRange>[window];
      final assigned = assignedByDay[a.dayOfWeek] ?? const <_MinuteRange>[];
      for (final block in assigned) {
        segments = segments.expand((segment) {
          if (block.end <= segment.start || block.start >= segment.end) {
            return [segment];
          }
          final next = <_MinuteRange>[];
          if (block.start > segment.start) {
            next.add(_MinuteRange(segment.start, block.start));
          }
          if (block.end < segment.end) {
            next.add(_MinuteRange(block.end, segment.end));
          }
          return next;
        }).toList();
      }

      for (final s in segments) {
        if ((s.end - s.start) >= 30) {
          freeSlots.add(
            '${_getDayName(a.dayOfWeek)} ${_formatMinutes(s.start)}-${_formatMinutes(s.end)}',
          );
        }
      }
    }

    return freeSlots;
  }

  String _formatMinutes(int totalMinutes) {
    final hour24 = totalMinutes ~/ 60;
    final minute = totalMinutes % 60;
    final period = hour24 >= 12 ? 'PM' : 'AM';
    var hour12 = hour24 % 12;
    if (hour12 == 0) hour12 = 12;
    final minuteText = minute.toString().padLeft(2, '0');
    return '$hour12:$minuteText$period';
  }

  Future<void> _printSchedulePdf(
    String facultyName,
    List<ScheduleInfo> schedules,
  ) async {
    final pdf = pw.Document();

    // Sort schedules by day then start time
    final sorted = List<ScheduleInfo>.from(schedules);
    final dayOrder = {
      DayOfWeek.mon: 0,
      DayOfWeek.tue: 1,
      DayOfWeek.wed: 2,
      DayOfWeek.thu: 3,
      DayOfWeek.fri: 4,
      DayOfWeek.sat: 5,
      DayOfWeek.sun: 6,
    };
    sorted.sort((a, b) {
      final da = dayOrder[a.schedule.timeslot?.day] ?? 99;
      final db = dayOrder[b.schedule.timeslot?.day] ?? 99;
      if (da != db) return da.compareTo(db);
      return (a.schedule.timeslot?.startTime ?? '').compareTo(
        b.schedule.timeslot?.startTime ?? '',
      );
    });

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
          // Header
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFF720045),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'TEACHING SCHEDULE',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  facultyName,
                  style: const pw.TextStyle(
                    color: PdfColor(1, 1, 1, 0.7),
                    fontSize: 14,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Generated: ${DateTime.now().toString().substring(0, 16)}',
                  style: const pw.TextStyle(
                    color: PdfColor(1, 1, 1, 0.55),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Table
          if (sorted.isEmpty)
            pw.Center(
              child: pw.Text(
                'No schedules assigned.',
                style: const pw.TextStyle(color: PdfColors.grey600),
              ),
            )
          else
            pw.Table(
              border: pw.TableBorder.all(
                color: PdfColors.grey300,
                width: 0.5,
              ),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.5), // Day
                1: const pw.FlexColumnWidth(2), // Time
                2: const pw.FlexColumnWidth(2.5), // Subject
                3: const pw.FlexColumnWidth(1.5), // Section
                4: const pw.FlexColumnWidth(1.5), // Room
              },
              children: [
                // Header row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFF720045),
                  ),
                  children: ['DAY', 'TIME', 'SUBJECT', 'SECTION', 'ROOM']
                      .map(
                        (h) => pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          child: pw.Text(
                            h,
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                // Data rows
                ...sorted.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final info = entry.value;
                  final s = info.schedule;
                  final ts = s.timeslot;
                  final bg = idx.isEven ? PdfColors.grey50 : PdfColors.white;
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: bg),
                    children: [
                      _pdfCell(_getDayName(ts?.day)),
                      _pdfCell(
                        ts != null ? '${ts.startTime} – ${ts.endTime}' : '—',
                      ),
                      _pdfCell(
                        s.subject?.name ?? s.subject?.code ?? '—',
                      ),
                      _pdfCell(s.section),
                      _pdfCell(s.room?.name ?? '—'),
                    ],
                  );
                }),
              ],
            ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Total: ${sorted.length} subject/s assigned',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  pw.Widget _pdfCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 10)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheduleAsync = ref.watch(facultyScheduleProvider);
    final availabilityAsync = ref.watch(facultyAvailabilityProvider);
    final user = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8F9FA);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Welcome Banner ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    maroonColor,
                    const Color(0xFF8e005b),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: maroonColor.withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: Colors.white.withOpacity(0.18),
                    child: Text(
                      (user?.userName?[0] ?? 'F').toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, Professor',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          user?.userName ?? 'Faculty Member',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Action Buttons
                  Row(
                    children: [
                      scheduleAsync.maybeWhen(
                        data: (schedules) => schedules.isEmpty
                            ? const SizedBox()
                            : ElevatedButton.icon(
                                onPressed: () => _printSchedulePdf(
                                  user?.userName ?? 'Faculty',
                                  schedules,
                                ),
                                icon: const Icon(Icons.print_rounded, size: 18),
                                label: Text(
                                  'Print Schedule',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: maroonColor,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                        orElse: () => const SizedBox(),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) =>
                                const LogoutConfirmationDialog(),
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
                ],
              ),
            ),

            const SizedBox(height: 28),

            scheduleAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (schedules) {
                final availabilities = availabilityAsync.maybeWhen(
                  data: (v) => v,
                  orElse: () => <FacultyAvailability>[],
                );
                final totalUnits = schedules.fold<double>(
                  0,
                  (sum, s) =>
                      sum +
                      (s.schedule.units ??
                          s.schedule.subject?.units.toDouble() ??
                          0),
                );
                final maxLoad = schedules.isNotEmpty
                    ? schedules.first.schedule.faculty?.maxLoad?.toDouble()
                    : null;
                final outsidePreferred = schedules
                    .where(
                      (s) => !_isWithinPreferredAvailability(
                        s.schedule,
                        availabilities,
                      ),
                    )
                    .length;
                final assignedHours = _computeAssignedHours(schedules);
                final preferredHours = _computePreferredHours(availabilities);
                final assignedWithinPreferred = _computeAssignedHoursWithinPreferred(
                  schedules,
                  availabilities,
                );
                final vacantHours = preferredHours > assignedWithinPreferred
                    ? preferredHours - assignedWithinPreferred
                    : 0.0;
                final freeSlots = _computeFreeSlotLabels(
                  schedules,
                  availabilities,
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _metricCard(
                            label: 'Assigned Units',
                            value: totalUnits.toStringAsFixed(1),
                            icon: Icons.stacked_bar_chart_rounded,
                            color: Colors.blue,
                            cardBg: cardBg,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _metricCard(
                            label: 'Max Load',
                            value: maxLoad?.toStringAsFixed(1) ?? '--',
                            icon: Icons.speed_rounded,
                            color: Colors.green,
                            cardBg: cardBg,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _metricCard(
                            label: 'Outside Preferred',
                            value: outsidePreferred.toString(),
                            icon: Icons.warning_amber_rounded,
                            color: outsidePreferred > 0
                                ? Colors.red
                                : Colors.orange,
                            cardBg: cardBg,
                          ),
                        ),
                      ],
                    ),
                    if (outsidePreferred > 0) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withOpacity(0.28)),
                        ),
                        child: Text(
                          '$outsidePreferred class(es) are outside your preferred availability window.',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.red[800],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _metricCard(
                            label: 'Assigned Hours',
                            value: assignedHours.toStringAsFixed(1),
                            icon: Icons.access_time_rounded,
                            color: Colors.indigo,
                            cardBg: cardBg,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _metricCard(
                            label: 'Vacant Hours',
                            value: vacantHours.toStringAsFixed(1),
                            icon: Icons.hourglass_bottom_rounded,
                            color: Colors.teal,
                            cardBg: cardBg,
                          ),
                        ),
                      ],
                    ),
                    if (freeSlots.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.teal.withOpacity(0.28),
                          ),
                        ),
                        child: Text(
                          'Free Slots: ${freeSlots.take(6).join(' | ')}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.teal[900],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                  ],
                );
              },
            ),

            // ── Tab bar ─────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: maroonColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: maroonColor.withOpacity(0.2),
                  ),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: maroonColor,
                unselectedLabelColor: Colors.grey[600],
                labelStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                unselectedLabelStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.view_week_rounded, size: 18),
                    text: 'Weekly Calendar',
                  ),
                  Tab(
                    icon: Icon(Icons.table_rows_rounded, size: 18),
                    text: 'Schedule Table',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Tab views ────────────────────────────────────────────
            scheduleAsync.when(
              loading: () => const Center(
                heightFactor: 5,
                child: CircularProgressIndicator(),
              ),
              error: (err, _) => Center(
                heightFactor: 4,
                child: Text(
                  'Error loading schedule: $err',
                  style: GoogleFonts.poppins(color: Colors.red),
                ),
              ),
              data: (schedules) {
                if (schedules.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_busy_rounded,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No schedules assigned yet.',
                          style: GoogleFonts.poppins(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return SizedBox(
                  height: 640,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // ── Tab 1: Calendar ──────────────────────────
                      availabilityAsync.when(
                        data: (availabilities) => WeeklyCalendarView(
                          schedules: schedules,
                          availabilities: availabilities,
                          maroonColor: maroonColor,
                        ),
                        loading: () => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        error: (err, _) => WeeklyCalendarView(
                          schedules: schedules,
                          maroonColor: maroonColor,
                        ),
                      ),

                      // ── Tab 2: Schedule Table ───────────────────
                      _buildScheduleTable(schedules, cardBg, isDark),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleTable(
    List<ScheduleInfo> schedules,
    Color cardBg,
    bool isDark,
  ) {
    // Sort by day then time
    final dayOrder = {
      DayOfWeek.mon: 0,
      DayOfWeek.tue: 1,
      DayOfWeek.wed: 2,
      DayOfWeek.thu: 3,
      DayOfWeek.fri: 4,
      DayOfWeek.sat: 5,
      DayOfWeek.sun: 6,
    };
    final sorted = List<ScheduleInfo>.from(schedules)
      ..sort((a, b) {
        final da = dayOrder[a.schedule.timeslot?.day] ?? 99;
        final db = dayOrder[b.schedule.timeslot?.day] ?? 99;
        if (da != db) return da.compareTo(db);
        return (a.schedule.timeslot?.startTime ?? '').compareTo(
          b.schedule.timeslot?.startTime ?? '',
        );
      });

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: maroonColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                _tableHeader('DAY', flex: 2),
                _tableHeader('TIME', flex: 3),
                _tableHeader('SUBJECT', flex: 4),
                _tableHeader('SECTION', flex: 2),
                _tableHeader('ROOM', flex: 2),
              ],
            ),
          ),

          // Rows
          Expanded(
            child: ListView.builder(
              itemCount: sorted.length,
              itemBuilder: (context, index) {
                final info = sorted[index];
                final s = info.schedule;
                final ts = s.timeslot;
                final hasConflict = info.conflicts.isNotEmpty;
                final isEven = index.isEven;

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: hasConflict
                        ? Colors.red.withOpacity(0.04)
                        : isEven
                        ? (isDark
                              ? Colors.white.withOpacity(0.02)
                              : Colors.grey.withOpacity(0.03))
                        : Colors.transparent,
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? Colors.white12 : Colors.grey.shade200,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      _tableCell(
                        flex: 2,
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: hasConflict ? Colors.red : maroonColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _getDayName(ts?.day),
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: hasConflict ? Colors.red : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _tableCell(
                        flex: 3,
                        child: Text(
                          ts != null ? '${ts.startTime} – ${ts.endTime}' : '—',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      _tableCell(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              s.subject?.name ?? '—',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (s.subject?.code != null)
                              Text(
                                s.subject!.code,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                      _tableCell(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: maroonColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            s.section,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: maroonColor,
                            ),
                          ),
                        ),
                      ),
                      _tableCell(
                        flex: 2,
                        child: Row(
                          children: [
                            Icon(
                              Icons.meeting_room_rounded,
                              size: 14,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              s.room?.name ?? '—',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: maroonColor.withOpacity(0.04),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 6),
                Text(
                  '${sorted.length} subject/s assigned this term',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color cardBg,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableHeader(String label, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _tableCell({required int flex, required Widget child}) {
    return Expanded(flex: flex, child: child);
  }
}

class _MinuteRange {
  final int start;
  final int end;

  const _MinuteRange(this.start, this.end);
}
