import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pumpq/models/insights_model.dart';
import 'package:pumpq/models/order_model.dart';
import 'package:pumpq/models/user_model.dart';

class ReportPdfService {
  static Future<void> exportPdf({
    required List<OrderModel> orders,
    BudgetInsightModel? budget,
    RefuelReminderModel? reminder,
    UserModel? user,
  }) async {
    final doc = pw.Document();

    final completed = orders.where((o) => o.status == 'completed').toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final totalSpent = completed.fold<double>(0.0, (sum, o) => sum + o.amount);
    final totalLiters = completed.fold<double>(0.0, (sum, o) => sum + o.liters);
    final avgPerOrder = completed.isEmpty ? 0.0 : totalSpent / completed.length;

    final primaryColor = PdfColor.fromHex('#E8450A');
    final secondaryColor = PdfColor.fromHex('#666666');
    final lightBg = PdfColor.fromHex('#F5F5F5');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'PumpQ',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  pw.Text(
                    'Fuel Expense & Analytics Report',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: secondaryColor,
                    ),
                  ),
                ],
              ),
              pw.Divider(color: primaryColor, thickness: 1.5),
              pw.SizedBox(height: 8),
            ],
          );
        },
        footer: (context) {
          return pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Generated on ${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}',
                style: pw.TextStyle(color: secondaryColor, fontSize: 10),
              ),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: pw.TextStyle(color: secondaryColor, fontSize: 10),
              ),
            ],
          );
        },
        build: (context) => [
          // Customer Details
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: lightBg,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Customer:', style: pw.TextStyle(fontSize: 10, color: secondaryColor)),
                    pw.Text(
                      user != null ? '${user.firstName} ${user.lastName}' : 'PumpQ Customer',
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Email:', style: pw.TextStyle(fontSize: 10, color: secondaryColor)),
                    pw.Text(user?.email ?? '-', style: const pw.TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // Section 1: Expense Summary
          pw.Text(
            'Expense Summary',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: primaryColor),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: _metricBox('Total Spent', 'PHP ${totalSpent.toStringAsFixed(2)}', primaryColor),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _metricBox('Total Liters', '${totalLiters.toStringAsFixed(1)} L', secondaryColor),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _metricBox('Completed Orders', '${completed.length}', secondaryColor),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _metricBox('Avg / Refuel', 'PHP ${avgPerOrder.toStringAsFixed(2)}', secondaryColor),
              ),
            ],
          ),
          pw.SizedBox(height: 16),

          // Section 2: Budget & AI Analytics Summary
          pw.Text(
            'AI Insights & Monthly Budget',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: primaryColor),
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (budget != null) ...[
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Monthly Budget: PHP ${budget.budget.toStringAsFixed(2)}'),
                      pw.Text('Spent this Month: PHP ${budget.spent.toStringAsFixed(2)} (${budget.percentUsed}%)'),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                ],
                if (reminder != null) ...[
                  if (reminder.hasEnoughData) ...[
                    pw.Text(
                      'AI Refuel Prediction: Average interval of ${reminder.averageIntervalDays?.toStringAsFixed(1)} days between refuels.',
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      (reminder.daysUntilNextRefuel ?? 0) <= 0
                          ? 'Status: Due for a refuel.'
                          : 'Status: Next refuel predicted in ${reminder.daysUntilNextRefuel} day(s).',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: primaryColor),
                    ),
                  ] else ...[
                    pw.Text('AI Refuel Prediction: Place more refuels to build prediction profile.'),
                  ],
                ],
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Section 3: Completed Orders Table
          pw.Text(
            'Order History',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: primaryColor),
          ),
          pw.SizedBox(height: 8),
          if (completed.isEmpty)
            pw.Text('No completed refuels found.', style: pw.TextStyle(color: secondaryColor))
          else
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.white),
              headerDecoration: pw.BoxDecoration(color: primaryColor),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignment: pw.Alignment.centerLeft,
              headerAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              headers: ['Order #', 'Date', 'Fuel Type', 'Liters', 'Amount', 'Payment'],
              data: completed.map((o) {
                final dateStr =
                    '${o.createdAt.year}-${o.createdAt.month.toString().padLeft(2, '0')}-${o.createdAt.day.toString().padLeft(2, '0')}';
                return [
                  '#${o.orderId}',
                  dateStr,
                  o.fuelType,
                  '${o.liters.toStringAsFixed(1)} L',
                  'PHP ${o.amount.toStringAsFixed(2)}',
                  o.paymentStatus,
                ];
              }).toList(),
            ),
        ],
      ),
    );

    final pdfBytes = await doc.save();
    await Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
      name: 'PumpQ_Expense_Report_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  static pw.Widget _metricBox(String label, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
          pw.SizedBox(height: 2),
          pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
