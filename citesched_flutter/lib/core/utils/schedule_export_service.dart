import 'package:citesched_client/citesched_client.dart';
import 'package:docx_creator/docx_creator.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ScheduleExportService {
  static Future<void> exportStudentSchedulePdf({
    required Student? student,
    required List<ScheduleInfo> schedules,
  }) async {
    final sorted = _sortedScheduleInfo(schedules);
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Text(
            'Student Class Schedule',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Student ID: ${student?.studentNumber ?? "-"}'),
          pw.Text('Name: ${student?.name ?? "-"}'),
          pw.Text('Program: ${student?.course ?? "-"}'),
          pw.Text('Section: ${student?.section ?? "-"}'),
          pw.Text('Year Level: ${student?.yearLevel ?? "-"}'),
          pw.SizedBox(height: 12),
          if (sorted.isEmpty)
            pw.Text('No schedules assigned.')
          else
            pw.Table.fromTextArray(
              headers: const [
                'Code',
                'Subject',
                'Instructor',
                'Room',
                'Day',
                'Time',
                'Section',
              ],
              data: sorted.map((info) {
                final s = info.schedule;
                final ts = s.timeslot;
                return [
                  s.subject?.code ?? '-',
                  s.subject?.name ?? '-',
                  s.faculty?.name ?? '-',
                  s.room?.name ?? '-',
                  _dayName(ts?.day),
                  ts == null ? '-' : '${ts.startTime}-${ts.endTime}',
                  s.section,
                ];
              }).toList(),
            ),
        ],
      ),
    );

    await Printing.layoutPdf(
      name: 'Student_Schedule_${student?.studentNumber ?? "student"}.pdf',
      onLayout: (format) => pdf.save(),
    );
  }

  static Future<String?> exportStudentScheduleDocx({
    required Student? student,
    required List<ScheduleInfo> schedules,
  }) async {
    final sorted = _sortedScheduleInfo(schedules);
    final rows = <List<String>>[
      ['Code', 'Subject', 'Instructor', 'Room', 'Day', 'Time', 'Section'],
      ...sorted.map((info) {
        final s = info.schedule;
        final ts = s.timeslot;
        return [
          s.subject?.code ?? '-',
          s.subject?.name ?? '-',
          s.faculty?.name ?? '-',
          s.room?.name ?? '-',
          _dayName(ts?.day),
          ts == null ? '-' : '${ts.startTime}-${ts.endTime}',
          s.section,
        ];
      }),
    ];

    final doc = docx()
        .h1('Student Class Schedule')
        .p('Student ID: ${student?.studentNumber ?? "-"}')
        .p('Name: ${student?.name ?? "-"}')
        .p('Program: ${student?.course ?? "-"}')
        .p('Section: ${student?.section ?? "-"}')
        .p('Year Level: ${student?.yearLevel ?? "-"}')
        .h2('Schedule')
        .table(rows)
        .build();

    final bytes = await DocxExporter().exportToBytes(doc);
    final fileName = 'Student_Schedule_${student?.studentNumber ?? "student"}.docx';
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Student Schedule DOCX',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: const ['docx'],
      bytes: bytes,
    );
    if (path != null) return path;
    return kIsWeb ? 'Downloaded in browser' : null;
  }

  static Future<void> exportFacultySchedulePdf({
    required String facultyName,
    required List<ScheduleInfo> schedules,
  }) async {
    final sorted = _sortedScheduleInfo(schedules);
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Text(
            'Faculty Teaching Schedule',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Faculty: $facultyName'),
          pw.SizedBox(height: 12),
          if (sorted.isEmpty)
            pw.Text('No schedules assigned.')
          else
            pw.Table.fromTextArray(
              headers: const [
                'Code',
                'Subject',
                'Section',
                'Room',
                'Day',
                'Time',
              ],
              data: sorted.map((info) {
                final s = info.schedule;
                final ts = s.timeslot;
                return [
                  s.subject?.code ?? '-',
                  s.subject?.name ?? '-',
                  s.section,
                  s.room?.name ?? '-',
                  _dayName(ts?.day),
                  ts == null ? '-' : '${ts.startTime}-${ts.endTime}',
                ];
              }).toList(),
            ),
        ],
      ),
    );

    await Printing.layoutPdf(
      name: 'Faculty_Schedule_${facultyName.replaceAll(" ", "_")}.pdf',
      onLayout: (format) => pdf.save(),
    );
  }

  static Future<String?> exportFacultyScheduleDocx({
    required String facultyName,
    required List<ScheduleInfo> schedules,
  }) async {
    final sorted = _sortedScheduleInfo(schedules);
    final rows = <List<String>>[
      ['Code', 'Subject', 'Section', 'Room', 'Day', 'Time'],
      ...sorted.map((info) {
        final s = info.schedule;
        final ts = s.timeslot;
        return [
          s.subject?.code ?? '-',
          s.subject?.name ?? '-',
          s.section,
          s.room?.name ?? '-',
          _dayName(ts?.day),
          ts == null ? '-' : '${ts.startTime}-${ts.endTime}',
        ];
      }),
    ];

    final doc = docx()
        .h1('Faculty Teaching Schedule')
        .p('Faculty: $facultyName')
        .h2('Schedule')
        .table(rows)
        .build();

    final bytes = await DocxExporter().exportToBytes(doc);
    final fileName = 'Faculty_Schedule_${facultyName.replaceAll(" ", "_")}.docx';
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Faculty Schedule DOCX',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: const ['docx'],
      bytes: bytes,
    );
    if (path != null) return path;
    return kIsWeb ? 'Downloaded in browser' : null;
  }

  static List<ScheduleInfo> _sortedScheduleInfo(List<ScheduleInfo> schedules) {
    final dayOrder = <DayOfWeek, int>{
      DayOfWeek.mon: 1,
      DayOfWeek.tue: 2,
      DayOfWeek.wed: 3,
      DayOfWeek.thu: 4,
      DayOfWeek.fri: 5,
      DayOfWeek.sat: 6,
      DayOfWeek.sun: 7,
    };
    final sorted = List<ScheduleInfo>.from(schedules);
    sorted.sort((a, b) {
      final ta = a.schedule.timeslot;
      final tb = b.schedule.timeslot;
      final da = ta == null ? 99 : (dayOrder[ta.day] ?? 99);
      final db = tb == null ? 99 : (dayOrder[tb.day] ?? 99);
      if (da != db) return da.compareTo(db);
      final sa = ta?.startTime ?? '';
      final sb = tb?.startTime ?? '';
      return sa.compareTo(sb);
    });
    return sorted;
  }

  static String _dayName(DayOfWeek? day) {
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
        return '-';
    }
  }
}
