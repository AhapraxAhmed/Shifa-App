import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../patients/data/models/patient_model.dart';
import '../../vitals/data/models/vital_model.dart';
import '../../medications/data/models/medication_model.dart';
import '../../notes/data/models/note_model.dart';
import '../../patients/data/models/history_event_model.dart';
import '../data/models/report_model.dart';

class ReportExporter {
  static Future<Uint8List> generatePatientReportPdf({
    required PatientModel patient,
    required List<VitalModel> vitals,
    required List<MedicationModel> meds,
    required List<NoteModel> notes,
    required List<HistoryEventModel> history,
  }) async {
    final pdf = pw.Document();
    
    // Format dates
    final df = DateFormat('dd MMM yyyy, hh:mm a');
    final nowStr = df.format(DateTime.now());
    final shiftStartedStr = patient.shiftStartedAt != null 
        ? df.format(patient.shiftStartedAt!) 
        : 'N/A';
    final shiftEndedStr = patient.shiftEndedAt != null 
        ? df.format(patient.shiftEndedAt!) 
        : 'N/A';

    final primaryColor = PdfColor.fromHex('#004D40'); // Dark Teal
    final lightGrey = PdfColor.fromHex('#F5F5F5');
    final darkGrey = PdfColor.fromHex('#212121');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (pw.Context context) => pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'SHIFA HOME HEALTH CARE',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 16,
                        color: primaryColor,
                      ),
                    ),
                    pw.Text(
                      'Enterprise Clinical Shift Report',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'MRN: ${patient.mrNumber}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: primaryColor),
                    ),
                    pw.Text(
                      'Generated: $nowStr',
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Divider(thickness: 1, color: primaryColor),
            pw.SizedBox(height: 10),
          ],
        ),
        footer: (pw.Context context) => pw.Column(
          children: [
            pw.Divider(thickness: 0.5, color: PdfColors.grey400),
            pw.SizedBox(height: 6),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Confidential Medical Document — For Professional Staff Only',
                  style: pw.TextStyle(fontSize: 7, fontStyle: pw.FontStyle.italic, color: PdfColors.grey600),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
                ),
              ],
            ),
          ],
        ),
        build: (pw.Context context) {
          return [
            // Patient details card
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: lightGrey,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'PATIENT DEMOGRAPHIC & ADMISSION PROFILE',
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: primaryColor),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            _pdfRow('Full Name', patient.patientName),
                            _pdfRow('Age / Gender', '${patient.age} Yrs / ${patient.gender}'),
                            _pdfRow('Home Address', patient.address),
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 16),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            _pdfRow('Assigned Nurse', patient.nurseName.isEmpty ? 'N/A' : patient.nurseName),
                            _pdfRow('Diagnosis', patient.diagnosis),
                            _pdfRow('Shift Status', '${patient.status.toUpperCase()} (${patient.isShiftActive ? "Active" : "Completed"})'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Shift Started: $shiftStartedStr',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
                      ),
                      pw.Text(
                        'Shift Ended: $shiftEndedStr',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Section: Vitals History
            pw.Text(
              '1. VITALS LOG & CLINICAL MEASUREMENTS',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: primaryColor),
            ),
            pw.SizedBox(height: 6),
            vitals.isEmpty
                ? pw.Text('No vitals recorded during this shift.', style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic))
                : pw.Table.fromTextArray(
                    border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.white),
                    headerDecoration: pw.BoxDecoration(color: primaryColor),
                    cellStyle: const pw.TextStyle(fontSize: 8),
                    cellAlignment: pw.Alignment.center,
                    headers: ['Time', 'BP', 'Temp (°C)', 'SPO₂ (%)', 'Pulse (bpm)', 'Sugar (mg/dL)', 'Resp (bpm)', 'By'],
                    data: vitals.map((v) {
                      final time = v.createdAt != null 
                          ? DateFormat('dd MMM, hh:mm a').format(v.createdAt!) 
                          : 'N/A';
                      return [
                        time,
                        v.bloodPressure,
                        '${v.temperature}°C',
                        '${v.oxygenLevel}%',
                        v.pulseRate,
                        v.bloodSugar,
                        v.respiratoryRate,
                        v.addedBy,
                      ];
                    }).toList(),
                  ),
            pw.SizedBox(height: 20),

            // Section: Medications
            pw.Text(
              '2. MEDICATION SCHEDULING & OBSERVATIONS',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: primaryColor),
            ),
            pw.SizedBox(height: 6),
            meds.isEmpty
                ? pw.Text('No medications prescribed or administered.', style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic))
                : pw.Table.fromTextArray(
                    border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.white),
                    headerDecoration: pw.BoxDecoration(color: primaryColor),
                    cellStyle: const pw.TextStyle(fontSize: 8),
                    cellAlignment: pw.Alignment.centerLeft,
                    headers: ['Medicine Name', 'Dosage', 'Schedule', 'Special Instructions / Notes', 'Date Added'],
                    data: meds.map((m) {
                      final time = m.createdAt != null 
                          ? DateFormat('dd MMM yyyy').format(m.createdAt!) 
                          : 'N/A';
                      return [
                        m.medicineName,
                        m.dosage,
                        m.schedule,
                        m.notes.isEmpty ? 'N/A' : m.notes,
                        time,
                      ];
                    }).toList(),
                  ),
            pw.SizedBox(height: 20),

            // Section: Clinical Notes
            pw.Text(
              '3. NURSE & CLINICIAN PROGRESS NOTES',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: primaryColor),
            ),
            pw.SizedBox(height: 6),
            notes.isEmpty
                ? pw.Text('No progress notes recorded.', style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic))
                : pw.Column(
                    children: notes.map((n) {
                      final time = n.createdAt != null 
                          ? DateFormat('dd MMM yyyy, hh:mm a').format(n.createdAt!) 
                          : 'N/A';
                      final editStr = n.isEdited ? ' (Edited by ${n.editedBy})' : '';
                      return pw.Container(
                        width: double.infinity,
                        margin: const pw.EdgeInsets.only(bottom: 8),
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text(
                                  'Attributed to: ${n.addedBy}$editStr',
                                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: primaryColor),
                                ),
                                pw.Text(
                                  time,
                                  style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
                                ),
                              ],
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              n.note,
                              style: const pw.TextStyle(fontSize: 8.5),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
            pw.SizedBox(height: 20),

            // Section: Activity History
            pw.Text(
              '4. SYSTEM AUDIT TRAIL & CLINICAL TIMELINE',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: primaryColor),
            ),
            pw.SizedBox(height: 6),
            history.isEmpty
                ? pw.Text('No logs recorded.', style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic))
                : pw.Column(
                    children: history.map((h) {
                      final time = h.createdAt != null 
                          ? DateFormat('dd MMM yyyy, hh:mm a').format(h.createdAt!) 
                          : 'N/A';
                      return pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Container(
                            margin: const pw.EdgeInsets.only(top: 3, right: 6),
                            width: 4,
                            height: 4,
                            decoration: pw.BoxDecoration(
                              shape: pw.BoxShape.circle,
                              color: primaryColor,
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  h.event,
                                  style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: darkGrey),
                                ),
                                pw.Text(
                                  'Time: $time  •  Type: ${h.type.toUpperCase()}',
                                  style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
                                ),
                                pw.SizedBox(height: 4),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$label: ',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.grey700),
            ),
            pw.TextSpan(
              text: value,
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.black),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> exportToPdf(ReportModel report) async {
    final pdf = pw.Document();
    final primaryColor = PdfColor.fromHex('#004D40');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('SHIFA HOME HEALTH CARE', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18, color: primaryColor)),
                    pw.Text('OFFICIAL REPORT', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Divider(thickness: 1, color: primaryColor),
                pw.SizedBox(height: 30),
                pw.Text('Report ID: ${report.id}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                pw.SizedBox(height: 10),
                pw.Text('Patient Name: ${report.patientName}', style: const pw.TextStyle(fontSize: 11)),
                pw.Text('MR Number: ${report.mrn}', style: const pw.TextStyle(fontSize: 11)),
                pw.Text('Report Type: ${report.reportType}', style: const pw.TextStyle(fontSize: 11)),
                pw.Text('Generating Staff: ${report.generatingStaff}', style: const pw.TextStyle(fontSize: 11)),
                pw.Text('Generated At: ${report.generatedAt.toString()}', style: const pw.TextStyle(fontSize: 11)),
                pw.SizedBox(height: 30),
                pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                pw.SizedBox(height: 20),
                pw.Text('REPORT DATA DETAILS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: primaryColor)),
                pw.SizedBox(height: 10),
                ...report.data.entries.map((e) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(e.key.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      pw.Text(e.value.toString(), style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                )),
              ],
            ),
          );
        },
      ),
    );

    final pdfData = await pdf.save();
    await Printing.sharePdf(bytes: pdfData, filename: 'Report_${report.id}.pdf');
  }
}
