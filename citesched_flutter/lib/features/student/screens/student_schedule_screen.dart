import 'package:citesched_client/citesched_client.dart';
import 'package:citesched_flutter/core/api/api_service.dart';
import 'package:citesched_flutter/features/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class StudentScheduleScreen extends ConsumerWidget {
  const StudentScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(studentScheduleProvider);
    final profileAsync = ref.watch(studentProfileProvider);
    final user = ref.watch(authProvider);

    final maroonDark = const Color(0xFF4f003b);
    final bgColor = const Color(0xFFF4F7F9);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'My Academic Schedule',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: maroonDark,
        elevation: 0,
        actions: [
          scheduleAsync.maybeWhen(
            data: (schedules) => schedules.isEmpty
                ? const SizedBox()
                : IconButton(
                    icon: const Icon(Icons.print_outlined),
                    onPressed: () => _printSchedulePdf(
                      profileAsync.value?.name ?? user?.userName ?? 'Student',
                      profileAsync.value?.section ?? 'Not Assigned',
                      schedules,
                    ),
                    tooltip: 'Print Schedule',
                  ),
            orElse: () => const SizedBox(),
          ),
          IconButton(
            onPressed: () => ref.read(authProvider.notifier).signOut(),
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Banner Section
            profileAsync.when(
              data: (profile) => _buildBanner(profile, user?.userName),
              loading: () => const LinearProgressIndicator(),
              error: (err, _) => _buildBanner(null, user?.userName),
            ),
            const SizedBox(height: 24),

            // Schedule Table Section
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(color: Colors.black.withOpacity(0.05)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: scheduleAsync.when(
                  data: (schedules) => _buildScheduleTable(schedules, context),
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(100),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (err, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(100),
                      child: Text('Error loading schedule: $err'),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
            Text(
              '© 2026 CITESched Academic Management System. All rights reserved.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _printSchedulePdf(
    String studentName,
    String section,
    List<Schedule> schedules,
  ) async {
    final pdf = pw.Document();

    final sorted = List<Schedule>.from(schedules);
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
      final da = dayOrder[a.timeslot?.day] ?? 99;
      final db = dayOrder[b.timeslot?.day] ?? 99;
      if (da != db) return da.compareTo(db);
      return (a.timeslot?.startTime ?? '').compareTo(
        b.timeslot?.startTime ?? '',
      );
    });

    double totalUnits = 0;
    for (var s in sorted) {
      totalUnits += s.subject?.units ?? 0;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
          // Header
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFF4f003b),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'UNIVERSITY ENROLLMENT RECORD',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  studentName.toUpperCase(),
                  style: const pw.TextStyle(
                    color: PdfColor(1, 1, 1, 0.9),
                    fontSize: 14,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Section: $section',
                  style: const pw.TextStyle(
                    color: PdfColor(1, 1, 1, 0.9),
                    fontSize: 12,
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
          pw.Table(
            border: pw.TableBorder.all(
              color: PdfColors.grey300,
              width: 0.5,
            ),
            columnWidths: {
              0: const pw.FlexColumnWidth(2.5),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(1.5),
              4: const pw.FlexColumnWidth(2.5),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFF4f003b),
                ),
                children: ['SUBJECT', 'UNITS', 'INSTRUCTOR', 'ROOM', 'SCHEDULE']
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
              ...sorted.asMap().entries.map((entry) {
                final idx = entry.key;
                final s = entry.value;
                final bg = idx.isEven ? PdfColors.grey50 : PdfColors.white;
                final ts = s.timeslot;
                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: bg),
                  children: [
                    _pdfCell(s.subject?.name ?? s.subject?.code ?? '—'),
                    _pdfCell(s.subject?.units.toString() ?? '0'),
                    _pdfCell(s.faculty?.name ?? 'TBA'),
                    _pdfCell(s.room?.name ?? 'TBA'),
                    _pdfCell(
                      ts != null
                          ? '${ts.day.name.toUpperCase()} ${ts.startTime} - ${ts.endTime}'
                          : 'N/A',
                    ),
                  ],
                );
              }),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Total Academic Load: ${totalUnits.toStringAsFixed(1)} Units',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: const PdfColor.fromInt(0xFF4f003b),
            ),
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

  Widget _buildBanner(Student? profile, String? userName) {
    final maroonDark = const Color(0xFF4f003b);
    final maroonLight = const Color(0xFF720045);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [maroonDark, maroonLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'UNIVERSITY ENROLLMENT RECORD',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(0.75),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                (profile?.name ?? userName ?? 'STUDENT').toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.school, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Section: ',
                    style: GoogleFonts.poppins(color: Colors.white70),
                  ),
                  Text(
                    profile?.section ?? 'Not Assigned',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  '2nd Semester | 2025-2026',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleTable(List<Schedule> schedules, BuildContext context) {
    if (schedules.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(80),
        child: Column(
          children: [
            Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No schedules found for your section.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    double totalUnits = 0;
    // Assuming each schedule represents a subject and we can sum units
    // In a real app, we'd group by subjectId to avoid duplicates if needed
    for (var s in schedules) {
      totalUnits += s.subject?.units ?? 0;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(Colors.grey[50]),
              columnSpacing: 24,
              columns: [
                DataColumn(
                  label: Text(
                    'SUBJECT DETAILS',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'UNITS',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'INSTRUCTOR',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'ROOM',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'SCHEDULE',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
              rows: [
                ...schedules.map((s) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFfdf2f8),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFFfbcfe8),
                                  ),
                                ),
                                child: Text(
                                  s.subject?.code ?? 'N/A',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF4f003b),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                s.subject?.name ?? 'Unknown Subject',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      DataCell(
                        Center(
                          child: Text(
                            s.subject?.units.toString() ?? '0',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          (s.faculty?.name ?? 'TBA').toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Text(
                            s.room?.name ?? 'TBA',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              s.timeslot?.day.name.toUpperCase() ?? 'N/A',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF4f003b),
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '${s.timeslot?.startTime} - ${s.timeslot?.endTime}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
                DataRow(
                  cells: [
                    DataCell(
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'TOTAL ACADEMIC LOAD:',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Center(
                        child: Text(
                          '${totalUnits.toStringAsFixed(1)} Units',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ),
                    const DataCell(SizedBox()),
                    const DataCell(SizedBox()),
                    const DataCell(SizedBox()),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
