import 'dart:typed_data';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/metrics_model.dart';
import '../models/report_model.dart';

typedef ExportResult = ({Uint8List bytes, String? s3Url});

class PdfExportService {
  PdfExportService._();
  static final PdfExportService instance = PdfExportService._();

  /// Genera el PDF y lo sube a S3 si Amplify está configurado.
  /// [s3Url] es null cuando S3 no está disponible — usar descarga local.
  Future<ExportResult> export({
    required ImpactMetrics metrics,
    required List<Report> reports,
  }) async {
    final bytes = await _buildPdf(metrics, reports);
    String? s3Url;
    try {
      if (Amplify.isConfigured) {
        s3Url = await _uploadToS3(bytes);
      }
    } catch (e) {
      debugPrint('S3 upload skipped: $e');
    }
    return (bytes: bytes, s3Url: s3Url);
  }

  // ── PDF ──────────────────────────────────────────────────────────────────────

  Future<Uint8List> _buildPdf(
    ImpactMetrics metrics,
    List<Report> reports,
  ) async {
    final doc = pw.Document(
      title: 'Reporte de Impacto — Master Ecology',
      author: 'Master Ecology Platform',
    );

    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    final green = PdfColor.fromHex('#2E7D32');
    final orange = PdfColor.fromHex('#F57C00');
    final red = PdfColor.fromHex('#D32F2F');
    final blue = PdfColor.fromHex('#1565C0');
    final bgGrey = PdfColor.fromHex('#F5F5F5');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (_) => _header(dateStr, green, orange),
        footer: (ctx) => _footer(ctx),
        build: (ctx) => [
          _sectionTitle('Indicadores de Impacto', green),
          pw.SizedBox(height: 8),
          pw.Row(children: [
            pw.Expanded(
                child: _kpiCard(
                    metrics.tonnesDeviated.toStringAsFixed(3),
                    'ton',
                    'Material Desviado',
                    green,
                    bgGrey)),
            pw.SizedBox(width: 8),
            pw.Expanded(
                child: _kpiCard(metrics.co2SavedKg.toStringAsFixed(1), 'kg',
                    'CO2 Evitado', orange, bgGrey)),
            pw.SizedBox(width: 8),
            pw.Expanded(
                child: _kpiCard('${metrics.completedReports}', '',
                    'Reportes Completados', green, bgGrey)),
            pw.SizedBox(width: 8),
            pw.Expanded(
                child: _kpiCard(
                    '${(metrics.completionRate * 100).toStringAsFixed(0)}',
                    '%',
                    'Tasa de Éxito',
                    orange,
                    bgGrey)),
          ]),
          pw.SizedBox(height: 6),
          pw.Row(children: [
            pw.Expanded(
                child: _kpiCard(
                    metrics.routeHoursOptimized.toStringAsFixed(1),
                    'hrs',
                    'Rutas Optimizadas',
                    green,
                    bgGrey)),
            pw.SizedBox(width: 8),
            pw.Expanded(
                child: _kpiCard('${metrics.totalReports}', '',
                    'Total de Reportes', green, bgGrey)),
            pw.SizedBox(width: 8),
            pw.Expanded(
                child: _kpiCard('${metrics.criticalPointsPending}', '',
                    'Puntos Críticos', red, bgGrey)),
            pw.SizedBox(width: 8),
            pw.Expanded(child: pw.SizedBox()),
          ]),
          pw.SizedBox(height: 22),
          if (metrics.reportsByMaterial.isNotEmpty) ...[
            _sectionTitle('Reportes por Material', green),
            pw.SizedBox(height: 8),
            _materialTable(metrics, green),
            pw.SizedBox(height: 22),
          ],
          _sectionTitle('Resumen por Estado', green),
          pw.SizedBox(height: 8),
          pw.Row(children: [
            pw.Expanded(
                child: _statusCard(
                    '${metrics.reportsByStatus['Pendiente'] ?? 0}',
                    'Pendiente',
                    orange,
                    bgGrey)),
            pw.SizedBox(width: 8),
            pw.Expanded(
                child: _statusCard(
                    '${metrics.reportsByStatus['En Camino'] ?? 0}',
                    'En Camino',
                    blue,
                    bgGrey)),
            pw.SizedBox(width: 8),
            pw.Expanded(
                child: _statusCard(
                    '${metrics.reportsByStatus['Completado'] ?? 0}',
                    'Completado',
                    green,
                    bgGrey)),
          ]),
          if (reports.isNotEmpty) ...[
            pw.SizedBox(height: 22),
            _sectionTitle(
                'Últimos Reportes (${reports.length > 10 ? '10 de ${reports.length}' : reports.length})',
                green),
            pw.SizedBox(height: 8),
            _reportsTable(reports.take(10).toList(), green),
          ],
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _header(String date, PdfColor green, PdfColor orange) {
    return pw.Column(children: [
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('Master Ecology',
                style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: green)),
            pw.Text('Reporte de Impacto Ambiental - Medellin',
                style: pw.TextStyle(fontSize: 11, color: orange)),
          ]),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text('Generado: $date',
                style: const pw.TextStyle(
                    fontSize: 9, color: PdfColors.grey600)),
            pw.Text('Gestión de Residuos',
                style: const pw.TextStyle(
                    fontSize: 9, color: PdfColors.grey600)),
          ]),
        ],
      ),
      pw.SizedBox(height: 4),
      pw.Divider(color: green, thickness: 1.5),
      pw.SizedBox(height: 10),
    ]);
  }

  pw.Widget _footer(pw.Context ctx) {
    return pw.Column(children: [
      pw.Divider(color: PdfColors.grey300, thickness: 0.5),
      pw.SizedBox(height: 3),
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text('Generado por Master Ecology Platform',
            style: const pw.TextStyle(
                fontSize: 8, color: PdfColors.grey500)),
        pw.Text('Pág. ${ctx.pageNumber} / ${ctx.pagesCount}',
            style: const pw.TextStyle(
                fontSize: 8, color: PdfColors.grey500)),
      ]),
    ]);
  }

  pw.Widget _sectionTitle(String title, PdfColor color) => pw.Text(
        title,
        style: pw.TextStyle(
            fontSize: 13, fontWeight: pw.FontWeight.bold, color: color),
      );

  pw.Widget _kpiCard(
      String value, String unit, String label, PdfColor accent, PdfColor bg) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: bg,
        // borderRadius no se puede combinar con Border no-uniforme en dart-pdf
        border: pw.Border(left: pw.BorderSide(color: accent, width: 3)),
      ),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
        pw.RichText(
          text: pw.TextSpan(children: [
            pw.TextSpan(
                text: value,
                style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: accent)),
            if (unit.isNotEmpty)
              pw.TextSpan(
                  text: ' $unit',
                  style: pw.TextStyle(fontSize: 10, color: accent)),
          ]),
        ),
        pw.SizedBox(height: 2),
        pw.Text(label,
            style:
                const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
      ]),
    );
  }

  pw.Widget _statusCard(
      String value, String label, PdfColor accent, PdfColor bg) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: pw.BoxDecoration(
        color: bg,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(children: [
        pw.Text(value,
            style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: accent)),
        pw.SizedBox(height: 3),
        pw.Text(label,
            style: const pw.TextStyle(
                fontSize: 9, color: PdfColors.grey700)),
      ]),
    );
  }

  pw.Widget _materialTable(ImpactMetrics metrics, PdfColor green) {
    final total =
        metrics.reportsByMaterial.values.fold(0, (a, b) => a + b);
    final sorted = metrics.reportsByMaterial.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey200, width: 0.5),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: green),
          children: [
            _th('Material'),
            _th('Reportes'),
            _th('Porcentaje'),
          ],
        ),
        ...sorted.map(
          (e) => pw.TableRow(children: [
            _td(e.key),
            _td('${e.value}'),
            _td('${(e.value / total * 100).toStringAsFixed(1)}%'),
          ]),
        ),
      ],
    );
  }

  pw.Widget _reportsTable(List<Report> reports, PdfColor green) {
    final fmt = DateFormat('dd/MM/yy');
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey200, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(2.5),
        1: pw.FlexColumnWidth(1.5),
        2: pw.FlexColumnWidth(1.5),
        3: pw.FlexColumnWidth(1.2),
        4: pw.FlexColumnWidth(1.2),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: green),
          children: [
            _th('Dirección'),
            _th('Material'),
            _th('Tipo'),
            _th('Estado'),
            _th('Fecha'),
          ],
        ),
        ...reports.map(
          (r) => pw.TableRow(children: [
            _td(r.location.address ?? '—', small: true),
            _td(r.material, small: true),
            _td(r.type, small: true),
            _td(r.status, small: true),
            _td(fmt.format(r.timestamp), small: true),
          ]),
        ),
      ],
    );
  }

  pw.Widget _th(String text) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: pw.Text(text,
            style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white)),
      );

  pw.Widget _td(String text, {bool small = false}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: pw.Text(text,
            style: pw.TextStyle(
                fontSize: small ? 7 : 9, color: PdfColors.grey800)),
      );

  // ── S3 ───────────────────────────────────────────────────────────────────────

  Future<String> _uploadToS3(Uint8List bytes) async {
    final filename =
        'master_ecology_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final path = 'public/reports/$filename';

    await Amplify.Storage.uploadData(
      path: StoragePath.fromString(path),
      data: StorageDataPayload.bytes(bytes, contentType: 'application/pdf'),
    ).result;

    final result = await Amplify.Storage.getUrl(
      path: StoragePath.fromString(path),
      options: StorageGetUrlOptions(
        pluginOptions: S3GetUrlPluginOptions(
          expiresIn: const Duration(hours: 1),
        ),
      ),
    ).result;

    return result.url.toString();
  }
}
