import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/metrics_provider.dart';
import '../../providers/reports_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(metricsProvider);
    final theme = Theme.of(context);
    final isWide = MediaQuery.of(context).size.width >= 720;

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard de Impacto')),
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
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Colors.red.shade700, size: 28),
            const SizedBox(width: 12),
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
                    style: TextStyle(color: Colors.red.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Alerta enviada a empresa de aseo ✓'),
                  backgroundColor: Colors.red.shade700,
                  behavior: SnackBarBehavior.floating,
                ),
              ),
              icon: const Icon(Icons.send, size: 14),
              label: const Text('Alertar', style: TextStyle(fontSize: 12)),
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
