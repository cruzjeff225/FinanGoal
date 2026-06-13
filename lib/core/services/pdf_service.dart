import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:finan_goal/features/transaction/models/transaction_model.dart';
import 'package:finan_goal/features/goals/models/saving_goal.dart';

class PdfService {
  PdfService._();

  static String _formatDate(DateTime d) {
    const months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    final timeStr = '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year} $timeStr';
  }

  static Future<File> generateReport({
    required List<TransactionModel> transactions,
    required List<SavingGoal> goals,
    required String userName,
  }) async {
    final pdf = pw.Document();

    // Calcular resúmenes
    final totalIncome = transactions
        .where((t) => t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);

    final totalExpense = transactions
        .where((t) => !t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);

    final balance = totalIncome - totalExpense;

    // Colores corporativos de FinanGoal
    final primaryColor = PdfColor.fromHex('#00C896');
    final secondaryColor = PdfColor.fromHex('#8FA3B1');
    final darkBgColor = PdfColor.fromHex('#0D1B2A');
    final errorColor = PdfColor.fromHex('#FF5C5C');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Cabecera del Reporte
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'FinanGoal',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    pw.Text(
                      'Reporte Financiero Personal',
                      style: pw.TextStyle(fontSize: 12, color: secondaryColor),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Usuario: $userName',
                      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'Generado: ${_formatDate(DateTime.now())}',
                      style: pw.TextStyle(fontSize: 9, color: secondaryColor),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Divider(color: primaryColor, thickness: 1.5),
            pw.SizedBox(height: 15),

            // Tarjetas de Resumen
            pw.Text(
              'RESUMEN GENERAL',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: darkBgColor),
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryBox('Balance Total', '\$${balance.toStringAsFixed(2)}', primaryColor),
                pw.SizedBox(width: 10),
                _buildSummaryBox('Total Ingresos', '\$${totalIncome.toStringAsFixed(2)}', primaryColor),
                pw.SizedBox(width: 10),
                _buildSummaryBox('Total Gastos', '\$${totalExpense.toStringAsFixed(2)}', errorColor),
              ],
            ),
            pw.SizedBox(height: 25),

            // Sección 1: Historial de Transacciones (Ingresos y Gastos)
            pw.Text(
              'HISTORIAL DE TRANSACCIONES',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: darkBgColor),
            ),
            pw.SizedBox(height: 8),
            if (transactions.isEmpty)
              pw.Text('No se encontraron transacciones registradas.', style: const pw.TextStyle(fontSize: 11))
            else
              pw.Table(
                border: const pw.TableBorder(
                  horizontalInside: pw.BorderSide(width: 0.5, color: PdfColors.grey300),
                  bottom: pw.BorderSide(width: 1, color: PdfColors.grey400),
                ),
                columnWidths: {
                  0: const pw.FixedColumnWidth(85), // Fecha
                  1: const pw.FixedColumnWidth(60), // Tipo
                  2: const pw.FixedColumnWidth(75), // Categoría
                  3: const pw.FixedColumnWidth(110), // Descripción
                  4: const pw.FixedColumnWidth(120), // Notas
                  5: const pw.FixedColumnWidth(70),  // Monto
                },
                children: [
                  // Encabezado tabla
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      _buildTableHeaderCell('Fecha'),
                      _buildTableHeaderCell('Tipo'),
                      _buildTableHeaderCell('Categoría'),
                      _buildTableHeaderCell('Descripción'),
                      _buildTableHeaderCell('Detalles/Notas'),
                      _buildTableHeaderCell('Monto', alignRight: true),
                    ],
                  ),
                  // Datos de tabla
                  ...transactions.map((tx) {
                    final txColor = tx.isIncome ? primaryColor : errorColor;
                    final txSign = tx.isIncome ? '+' : '-';
                    return pw.TableRow(
                      children: [
                        _buildTableCell(_formatDateShort(tx.date)),
                        _buildTableCell(tx.isIncome ? 'Ingreso' : 'Gasto', color: txColor),
                        _buildTableCell(tx.category),
                        _buildTableCell(tx.description),
                        _buildTableCell(tx.notes ?? '-'),
                        _buildTableCell('$txSign\$${tx.amount.toStringAsFixed(2)}', color: txColor, alignRight: true),
                      ],
                    );
                  }).toList(),
                ],
              ),
            pw.SizedBox(height: 25),

            // Sección 2: Metas de Ahorro y Abonos
            pw.Text(
              'ESTADO DE METAS DE AHORRO',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: darkBgColor),
            ),
            pw.SizedBox(height: 8),
            if (goals.isEmpty)
              pw.Text('No se encontraron metas de ahorro activas.', style: const pw.TextStyle(fontSize: 11))
            else
              pw.Table(
                border: const pw.TableBorder(
                  horizontalInside: pw.BorderSide(width: 0.5, color: PdfColors.grey300),
                  bottom: pw.BorderSide(width: 1, color: PdfColors.grey400),
                ),
                columnWidths: {
                  0: const pw.FixedColumnWidth(40),  // Emoji
                  1: const pw.FixedColumnWidth(180), // Meta
                  2: const pw.FixedColumnWidth(100), // Ahorrado
                  3: const pw.FixedColumnWidth(100), // Objetivo
                  4: const pw.FixedColumnWidth(100), // Progreso %
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      _buildTableHeaderCell('Icono'),
                      _buildTableHeaderCell('Meta de Ahorro'),
                      _buildTableHeaderCell('Ahorrado'),
                      _buildTableHeaderCell('Objetivo'),
                      _buildTableHeaderCell('Progreso', alignRight: true),
                    ],
                  ),
                  ...goals.map((g) {
                    final progressPercent = (g.progress * 100).toStringAsFixed(1);
                    return pw.TableRow(
                      children: [
                        _buildTableCell(g.emoji),
                        _buildTableCell(g.name),
                        _buildTableCell('\$${g.savedAmount.toStringAsFixed(2)}'),
                        _buildTableCell('\$${g.targetAmount.toStringAsFixed(2)}'),
                        _buildTableCell('$progressPercent%', alignRight: true),
                      ],
                    );
                  }).toList(),
                ],
              ),
          ];
        },
      ),
    );

    // Obtener directorio local y guardar el archivo PDF
    final docDir = await getApplicationDocumentsDirectory();
    final reportsDir = Directory('${docDir.path}/reports');
    if (!await reportsDir.exists()) {
      await reportsDir.create(recursive: true);
    }

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
    final file = File('${reportsDir.path}/Reporte_Financiero_$timestamp.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static String _formatDateShort(DateTime d) {
    const months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }

  static pw.Widget _buildSummaryBox(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: color, width: 1),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          color: PdfColors.grey50,
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              value,
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildTableHeaderCell(String text, {bool alignRight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: pw.Text(
        text,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
      ),
    );
  }

  static pw.Widget _buildTableCell(String text, {PdfColor? color, bool alignRight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: pw.Text(
        text,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: 9,
          color: color ?? PdfColors.grey800,
        ),
      ),
    );
  }
}
