import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:citesched_client/citesched_client.dart';
import 'package:docx_creator/docx_creator.dart';
import 'package:file_picker/file_picker.dart';

class PdfGenerator {
  // ─────────────────────────── PDF EXPORT ───────────────────────────────────

  /// Opens the system print/save-PDF dialog for a single faculty summary.
  static Future<void> printFacultySummaryAsPdf(
    FacultyLoadReport report,
    List<Schedule> allSchedules,
  ) async {
    final pdf = pw.Document();
    final facultySchedules = allSchedules
        .where((s) => s.facultyId == report.facultyId)
        .toList();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Faculty Schedule Summary',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              _buildSummaryRow('Faculty Name:', report.facultyName),
              _buildSummaryRow('Program:', report.program ?? '—'),
              _buildSummaryRow(
                'Total Units:',
                report.totalUnits.toStringAsFixed(0),
              ),
              _buildSummaryRow(
                'Total Hours:',
                '${report.totalHours.toStringAsFixed(1)} hrs',
              ),
              _buildSummaryRow('Subjects Handled:', '${report.totalSubjects}'),
              _buildSummaryRow('Load Status:', report.loadStatus),
              pw.SizedBox(height: 30),
              pw.Text(
                'Assigned Subjects',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              _buildScheduleTable(facultySchedules),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Faculty_Summary_${report.facultyName.replaceAll(' ', '_')}.pdf',
    );
  }

  /// Opens the system print/save-PDF dialog for all faculty summary.
  static Future<void> printAllSummaryAsPdf(
    List<FacultyLoadReport> reports,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                'All Faculty Summary',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headers: [
                'Faculty Name',
                'Program',
                'Units',
                'Hours',
                'Subjects',
                'Status',
              ],
              data: reports
                  .map(
                    (r) => [
                      r.facultyName,
                      r.program ?? '—',
                      r.totalUnits.toStringAsFixed(0),
                      '${r.totalHours.toStringAsFixed(1)} hrs',
                      r.totalSubjects.toString(),
                      r.loadStatus,
                    ],
                  )
                  .toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              cellHeight: 30,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerRight,
                5: pw.Alignment.center,
              },
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'All_Faculty_Summary.pdf',
    );
  }

  // ─────────────────────────── WORD/DOCX EXPORT ─────────────────────────────

  /// Generates a .docx Word document for a single faculty summary and saves it.
  /// Returns the saved file path (null on web).
  static Future<String?> exportFacultySummaryAsDocx(
    FacultyLoadReport report,
    List<Schedule> allSchedules,
  ) async {
    final facultySchedules = allSchedules
        .where((s) => s.facultyId == report.facultyId)
        .toList();

    // Build table rows
    final tableRows = <List<String>>[
      ['Subject', 'Section', 'Units', 'Room', 'Schedule'],
      ...facultySchedules.map(
        (s) => [
          s.subject?.name ?? 'Unknown',
          s.section,
          s.units?.toString() ?? s.subject?.units.toString() ?? '0',
          s.room?.name ?? 'TBA',
          s.timeslot != null
              ? '${s.timeslot!.day.name.substring(0, 3)} ${s.timeslot!.startTime}-${s.timeslot!.endTime}'
              : 'TBA',
        ],
      ),
    ];

    final doc = docx()
        .h1('Faculty Schedule Summary')
        .p('Faculty Name: ${report.facultyName}')
        .p('Program: ${report.program ?? '—'}')
        .p('Total Units: ${report.totalUnits.toStringAsFixed(0)}')
        .p('Total Hours: ${report.totalHours.toStringAsFixed(1)} hrs')
        .p('Subjects Handled: ${report.totalSubjects}')
        .p('Load Status: ${report.loadStatus}')
        .h2('Assigned Subjects')
        .table(tableRows)
        .build();

    final fileName =
        'Faculty_Summary_${report.facultyName.replaceAll(' ', '_')}.docx';
    return _saveDocx(doc, fileName);
  }

  /// Generates a .docx Word document for all faculty and saves it.
  /// Returns the saved file path (null on web).
  static Future<String?> exportAllSummaryAsDocx(
    List<FacultyLoadReport> reports,
  ) async {
    final tableRows = <List<String>>[
      ['Faculty Name', 'Program', 'Units', 'Hours', 'Subjects', 'Status'],
      ...reports.map(
        (r) => [
          r.facultyName,
          r.program ?? '—',
          r.totalUnits.toStringAsFixed(0),
          '${r.totalHours.toStringAsFixed(1)} hrs',
          r.totalSubjects.toString(),
          r.loadStatus,
        ],
      ),
    ];

    final doc = docx()
        .h1('All Faculty Summary')
        .p('CITESched Faculty Loading Report — AY 2025-2026')
        .h2('Faculty Overview')
        .table(tableRows)
        .build();

    return _saveDocx(doc, 'All_Faculty_Summary.docx');
  }

  // ─────────────────────────── HELPERS ──────────────────────────────────────

  /// Saves a [DocxBuiltDocument] to the downloads/documents folder.
  /// Returns the saved file path, or null on web.
  static Future<String?> _saveDocx(
    DocxBuiltDocument doc,
    String fileName,
  ) async {
    try {
      final bytes = await DocxExporter().exportToBytes(doc);
      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save DOCX',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: const ['docx'],
        bytes: bytes,
      );
      if (savedPath != null) return savedPath;
      return kIsWeb ? 'Downloaded in browser' : null;
    } catch (e) {
      return null;
    }
  }

  static pw.Widget _buildSummaryRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 150,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildScheduleTable(List<Schedule> schedules) {
    if (schedules.isEmpty) {
      return pw.Text(
        'No schedules assigned.',
        style: const pw.TextStyle(color: PdfColors.grey),
      );
    }

    return pw.Table.fromTextArray(
      headers: ['Subject', 'Section', 'Units', 'Room', 'Schedule'],
      data: schedules
          .map(
            (s) => [
              s.subject?.name ?? 'Unknown',
              s.section,
              s.units?.toString() ?? s.subject?.units.toString() ?? '0',
              s.room?.name ?? 'TBA',
              s.timeslot != null
                  ? '${s.timeslot!.day.name.substring(0, 3)} ${s.timeslot!.startTime}-${s.timeslot!.endTime}'
                  : 'TBA',
            ],
          )
          .toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellHeight: 25,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerLeft,
        4: pw.Alignment.centerLeft,
      },
    );
  }
}
