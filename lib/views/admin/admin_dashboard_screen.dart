import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/metrics_provider.dart';
import '../../providers/reports_provider.dart';
import '../../services/amplify_service.dart';
import '../../services/pdf_export_service.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(metricsProvider);
    final theme = Theme.of(context);
    final isWide = MediaQuery.of(context).size.width >= 720;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard de Impacto'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Análisis IA con Bedrock',
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const _AiInsightDialog(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Exportar reporte PDF',
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const _ExportReportDialog(),
            ),
          ),
        ],
      ),
      body: metricsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (metrics) => RefreshIndicator(
          onRefresh: () => ref.refresh(metricsProvider.future),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Critical points alert
                if (metrics.criticalPointsPending > 0) ...[
                  _CriticalPointsAlert(count: metrics.criticalPointsPending),
                  const SizedBox(height: 16),
                ],
                Text('Resumen General',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                // Impact KPI cards
                isWide
                    ? Row(
                        children: [
                          Expanded(
                              child: _ImpactCard(
                            value: metrics.tonnesDeviated
                                .toStringAsFixed(3),
                            unit: 'Toneladas',
                            label: 'Material desviado',
                            icon: Icons.scale,
                            color: AppColors.forestGreen,
                          )),
                          const SizedBox(width: 16),
                          Expanded(
                              child: _ImpactCard(
                            value: metrics.co2SavedKg.toStringAsFixed(1),
                            unit: 'kg CO₂',
                            label: 'Emisiones evitadas',
                            icon: Icons.cloud_off,
                            color: AppColors.techOrange,
                          )),
                          const SizedBox(width: 16),
                          Expanded(
                              child: _ImpactCard(
                            value: metrics.completedReports.toString(),
                            unit: 'Reportes',
                            label: 'Completados',
                            icon: Icons.check_circle,
                            color: AppColors.completed,
                          )),
                          const SizedBox(width: 16),
                          Expanded(
                              child: _ImpactCard(
                            value:
                                '${(metrics.completionRate * 100).toStringAsFixed(0)}%',
                            unit: '',
                            label: 'Tasa de éxito',
                            icon: Icons.trending_up,
                            color: AppColors.onTheWay,
                          )),
                        ],
                      )
                    : Column(
                        children: [
                          Row(children: [
                            Expanded(
                                child: _ImpactCard(
                              value: metrics.tonnesDeviated
                                  .toStringAsFixed(3),
                              unit: 'Ton',
                              label: 'Material desviado',
                              icon: Icons.scale,
                              color: AppColors.forestGreen,
                            )),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _ImpactCard(
                              value:
                                  metrics.co2SavedKg.toStringAsFixed(1),
                              unit: 'kg CO₂',
                              label: 'CO₂ evitado',
                              icon: Icons.cloud_off,
                              color: AppColors.techOrange,
                            )),
                          ]),
                          const SizedBox(height: 12),
                          Row(children: [
                            Expanded(
                                child: _ImpactCard(
                              value:
                                  metrics.completedReports.toString(),
                              unit: '',
                              label: 'Completados',
                              icon: Icons.check_circle,
                              color: AppColors.completed,
                            )),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _ImpactCard(
                              value:
                                  '${(metrics.completionRate * 100).toStringAsFixed(0)}%',
                              unit: '',
                              label: 'Tasa de éxito',
                              icon: Icons.trending_up,
                              color: AppColors.onTheWay,
                            )),
                          ]),
                        ],
                      ),

                const SizedBox(height: 16),
                _RouteHoursCard(hours: metrics.routeHoursOptimized),

                const SizedBox(height: 28),
                Text('Filtrar mapa por material',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const _MaterialFilterBar(),

                const SizedBox(height: 28),
                Text('Reportes por Material',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _MaterialBreakdown(data: metrics.reportsByMaterial),

                const SizedBox(height: 28),
                Text('Reportes por Estado',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _StatusBreakdown(
                    data: metrics.reportsByStatus,
                    total: metrics.totalReports),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ImpactCard extends StatelessWidget {
  final String value;
  final String unit;
  final String label;
  final IconData icon;
  final Color color;

  const _ImpactCard({
    required this.value,
    required this.unit,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  if (unit.isNotEmpty)
                    TextSpan(
                      text: ' $unit',
                      style: TextStyle(
                          fontSize: 13, color: color.withValues(alpha: 0.7)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _MaterialBreakdown extends StatelessWidget {
  final Map<String, int> data;
  const _MaterialBreakdown({required this.data});

  @override
  Widget build(BuildContext context) {
    final total = data.values.fold(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    final sorted = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: sorted.map((entry) {
            final color =
                AppColors.materialColors[entry.key] ?? AppColors.forestGreen;
            final pct = entry.value / total;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(entry.key)),
                      Text('${entry.value}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Text('${(pct * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: color.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _StatusBreakdown extends StatelessWidget {
  final Map<String, int> data;
  final int total;

  const _StatusBreakdown({required this.data, required this.total});

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        label: 'Pendiente',
        color: AppColors.pending,
        count: data['Pendiente'] ?? 0
      ),
      (
        label: 'En Camino',
        color: AppColors.onTheWay,
        count: data['En Camino'] ?? 0
      ),
      (
        label: 'Completado',
        color: AppColors.completed,
        count: data['Completado'] ?? 0
      ),
    ];

    return Row(
      children: items.map((item) {
        return Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Column(
                children: [
                  Text(
                    item.count.toString(),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: item.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Critical points alert card ───────────────────────────────────────────────

class _CriticalPointsAlert extends StatelessWidget {
  final int count;
  const _CriticalPointsAlert({required this.count});

  @override
  Widget build(BuildContext context) {
    final plural = count > 1;
    return Card(
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red.shade300, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        // Column layout keeps the button from overflowing on small screens
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.red.shade700, size: 26),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$count Punto${plural ? 's' : ''} Crítico${plural ? 's' : ''} sin atender',
                        style: TextStyle(
                          color: Colors.red.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Se recomienda alertar a la empresa de aseo.',
                        style:
                            TextStyle(color: Colors.red.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Alerta enviada a empresa de aseo ✓'),
                    backgroundColor: Colors.red.shade700,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                icon: const Icon(Icons.send, size: 14),
                label: const Text('Alertar', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Route hours KPI card ─────────────────────────────────────────────────────

class _RouteHoursCard extends StatelessWidget {
  final double hours;
  const _RouteHoursCard({required this.hours});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.forestGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.route,
                  color: AppColors.forestGreen, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${hours.toStringAsFixed(1)} horas optimizadas',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.forestGreen,
                    ),
                  ),
                  const Text(
                    'Rutas de recicladores dignificadas · 15 min/reporte',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Material quick-filter bar (affects the map in real time via filterProvider)

class _MaterialFilterBar extends ConsumerWidget {
  const _MaterialFilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(filterProvider);
    final notifier = ref.read(filterProvider.notifier);

    const quickMaterials = [
      WasteMaterial.plastic,
      WasteMaterial.metal,
      WasteMaterial.glass,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ActionChip(
          avatar: Icon(Icons.layers_clear,
              size: 16,
              color: filter.materials.isEmpty
                  ? AppColors.forestGreen
                  : Colors.grey),
          label: const Text('Todos'),
          backgroundColor: filter.materials.isEmpty
              ? AppColors.forestGreen.withValues(alpha: 0.12)
              : null,
          onPressed: notifier.clearAll,
        ),
        ...quickMaterials.map((m) {
          final color =
              AppColors.materialColors[m] ?? AppColors.forestGreen;
          final active = filter.materials.contains(m);
          return FilterChip(
            label: Text(m),
            selected: active,
            selectedColor: color.withValues(alpha: 0.18),
            checkmarkColor: color,
            labelStyle: TextStyle(
              color: active ? color : null,
              fontWeight: active ? FontWeight.w600 : null,
            ),
            onSelected: (_) => notifier.toggleMaterial(m),
          );
        }),
      ],
    );
  }
}

// ── Export report dialog ──────────────────────────────────────────────────────

enum _ExportPhase { idle, working, done, failed }

class _ExportReportDialog extends ConsumerStatefulWidget {
  const _ExportReportDialog();

  @override
  ConsumerState<_ExportReportDialog> createState() =>
      _ExportReportDialogState();
}

class _ExportReportDialogState extends ConsumerState<_ExportReportDialog> {
  _ExportPhase _phase = _ExportPhase.idle;
  String _step = '';
  Uint8List? _pdfBytes;
  String? _s3Url;
  String? _errorMsg;
  bool _urlCopied = false;

  Future<void> _runExport() async {
    setState(() {
      _phase = _ExportPhase.working;
      _step = 'Compilando métricas de impacto...';
    });

    try {
      final metrics = await ref.read(metricsProvider.future);
      final reports =
          ref.read(reportsNotifierProvider).valueOrNull ?? [];

      setState(() => _step = 'Generando PDF...');

      final result = await PdfExportService.instance.export(
        metrics: metrics,
        reports: reports,
      );

      setState(() {
        _pdfBytes = result.bytes;
        _s3Url = result.s3Url;
        _phase = _ExportPhase.done;
      });
    } catch (e) {
      setState(() {
        _phase = _ExportPhase.failed;
        _errorMsg = e.toString();
      });
    }
  }

  Future<void> _downloadLocally() async {
    if (_pdfBytes == null) return;
    await Printing.sharePdf(
      bytes: _pdfBytes!,
      filename: 'master_ecology_report.pdf',
    );
  }

  Future<void> _copyUrl() async {
    if (_s3Url == null) return;
    await Clipboard.setData(ClipboardData(text: _s3Url!));
    setState(() => _urlCopied = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _urlCopied = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.picture_as_pdf, color: AppColors.techOrange),
          SizedBox(width: 10),
          Text('Exportar Reporte PDF'),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: switch (_phase) {
          _ExportPhase.idle => const Text(
              'Genera un PDF con el resumen de impacto ambiental '
              'para compartir con stakeholders y entidades de la ciudad.',
            ),
          _ExportPhase.working => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  backgroundColor:
                      AppColors.techOrange.withValues(alpha: 0.15),
                  valueColor:
                      const AlwaysStoppedAnimation(AppColors.techOrange),
                ),
                const SizedBox(height: 14),
                const _LogLine('> Conectando con el servicio...', done: true),
                _LogLine('> $_step', done: false),
              ],
            ),
          _ExportPhase.done => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.check_circle,
                      color: AppColors.forestGreen, size: 20),
                  const SizedBox(width: 8),
                  Text('PDF generado correctamente',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 14),
                if (_s3Url != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.forestGreen.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.forestGreen.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(children: [
                          Icon(Icons.cloud_done,
                              color: AppColors.forestGreen, size: 16),
                          SizedBox(width: 6),
                          Text('Subido a S3',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.forestGreen)),
                        ]),
                        const SizedBox(height: 6),
                        Text(
                          _s3Url!.length > 60
                              ? '${_s3Url!.substring(0, 60)}…'
                              : _s3Url!,
                          style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10,
                              color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.forestGreen,
                            side: const BorderSide(
                                color: AppColors.forestGreen),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                          ),
                          onPressed: _copyUrl,
                          icon: Icon(
                              _urlCopied
                                  ? Icons.check
                                  : Icons.copy,
                              size: 14),
                          label: Text(_urlCopied ? 'Copiado' : 'Copiar URL',
                              style: const TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.techOrange),
                  onPressed: _downloadLocally,
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Descargar PDF'),
                ),
              ],
            ),
          _ExportPhase.failed => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.error_outline,
                      color: Colors.red.shade600, size: 20),
                  const SizedBox(width: 8),
                  Text('Error al exportar',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 8),
                Text(
                  _errorMsg ?? 'Error desconocido',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
        },
      ),
      actions: switch (_phase) {
        _ExportPhase.idle => [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.techOrange),
              onPressed: _runExport,
              icon: const Icon(Icons.picture_as_pdf, size: 16),
              label: const Text('Generar PDF'),
            ),
          ],
        _ExportPhase.working => const [],
        _ExportPhase.done || _ExportPhase.failed => [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
            if (_phase == _ExportPhase.failed)
              FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.techOrange),
                onPressed: _runExport,
                child: const Text('Reintentar'),
              ),
          ],
      },
    );
  }
}

class _LogLine extends StatelessWidget {
  final String text;
  final bool done;
  const _LogLine(this.text, {required this.done});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        if (done)
          const Icon(Icons.check, size: 14, color: AppColors.forestGreen)
        else
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            color: done
                ? AppColors.forestGreen
                : Colors.grey.shade700,
          ),
        ),
      ]),
    );
  }
}

// ── AI Insight Dialog (Bedrock executive analysis) ────────────────────────────

enum _InsightPhase { idle, working, done, failed }

class _AiInsightDialog extends ConsumerStatefulWidget {
  const _AiInsightDialog();

  @override
  ConsumerState<_AiInsightDialog> createState() => _AiInsightDialogState();
}

class _AiInsightDialogState extends ConsumerState<_AiInsightDialog> {
  _InsightPhase _phase = _InsightPhase.idle;
  String _insight = '';
  String? _errorMsg;

  Future<void> _generate() async {
    setState(() => _phase = _InsightPhase.working);
    try {
      final metrics = await ref.read(metricsProvider.future);
      final text = await AmplifyService.instance.generateEcoInsight(metrics);
      setState(() {
        _insight = text;
        _phase = _InsightPhase.done;
      });
    } catch (e) {
      setState(() {
        _errorMsg = e.toString();
        _phase = _InsightPhase.failed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.auto_awesome, color: AppColors.techOrange),
          SizedBox(width: 10),
          Text('Análisis IA de Impacto'),
        ],
      ),
      content: SizedBox(
        width: 460,
        child: switch (_phase) {
          _InsightPhase.idle => const Text(
              'Genera un análisis ejecutivo en español con Amazon Bedrock '
              '(Claude Haiku) basado en las métricas actuales de la plataforma.',
            ),
          _InsightPhase.working => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  backgroundColor:
                      AppColors.techOrange.withValues(alpha: 0.15),
                  valueColor:
                      const AlwaysStoppedAnimation(AppColors.techOrange),
                ),
                const SizedBox(height: 14),
                const _LogLine('> Leyendo métricas de impacto…', done: true),
                const _LogLine('> Invocando Amazon Bedrock (Claude Haiku)…',
                    done: false),
              ],
            ),
          _InsightPhase.done => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.auto_awesome,
                      color: AppColors.techOrange, size: 18),
                  const SizedBox(width: 8),
                  Text('Generado por Amazon Bedrock',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: AppColors.techOrange)),
                ]),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.forestGreen.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.forestGreen.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    _insight,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(height: 1.55),
                  ),
                ),
              ],
            ),
          _InsightPhase.failed => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.error_outline,
                      color: Colors.red.shade600, size: 20),
                  const SizedBox(width: 8),
                  Text('Error al generar análisis',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 8),
                Text(_errorMsg ?? 'Error desconocido',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade700)),
              ],
            ),
        },
      ),
      actions: switch (_phase) {
        _InsightPhase.idle => [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.techOrange),
              onPressed: _generate,
              icon: const Icon(Icons.auto_awesome, size: 16),
              label: const Text('Generar con IA'),
            ),
          ],
        _InsightPhase.working => const [],
        _InsightPhase.done || _InsightPhase.failed => [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
            if (_phase == _InsightPhase.failed)
              FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.techOrange),
                onPressed: _generate,
                child: const Text('Reintentar'),
              ),
          ],
      },
    );
  }
}
