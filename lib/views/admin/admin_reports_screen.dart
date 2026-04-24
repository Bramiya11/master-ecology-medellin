import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/report_model.dart';
import '../../providers/reports_provider.dart';

class AdminReportsScreen extends ConsumerWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(reportsNotifierProvider);
    final filter = ref.watch(filterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Reportes'),
        actions: [
          if (filter.hasActiveFilters)
            IconButton(
              icon: const Icon(Icons.filter_alt_off),
              tooltip: 'Limpiar filtros',
              onPressed: () => ref.read(filterProvider.notifier).clearAll(),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(reportsNotifierProvider.notifier).refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          _StatusFilterBar(filter: filter),
          Expanded(
            child: reportsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (reports) {
                final filtered = filter.hasActiveFilters
                    ? reports.where(filter.matches).toList()
                    : reports;

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('No hay reportes con estos filtros'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) =>
                      _AdminReportTile(report: filtered[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusFilterBar extends ConsumerWidget {
  final ReportFilter filter;
  const _StatusFilterBar({required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(filterProvider.notifier);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ReportStatus.all.map((status) {
            final color = switch (status) {
              ReportStatus.pending => AppColors.pending,
              ReportStatus.onTheWay => AppColors.onTheWay,
              _ => AppColors.completed,
            };
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(status),
                selected: filter.statuses.contains(status),
                onSelected: (_) => notifier.toggleStatus(status),
                selectedColor: color.withValues(alpha: 0.2),
                checkmarkColor: color,
                labelStyle: TextStyle(
                  color: filter.statuses.contains(status) ? color : null,
                  fontWeight: filter.statuses.contains(status)
                      ? FontWeight.w600
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _AdminReportTile extends ConsumerWidget {
  final Report report;
  const _AdminReportTile({required this.report});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final materialColor =
        AppColors.materialColors[report.material] ?? AppColors.forestGreen;
    final statusColor = switch (report.status) {
      ReportStatus.pending => AppColors.pending,
      ReportStatus.onTheWay => AppColors.onTheWay,
      _ => AppColors.completed,
    };
    final fmt = DateFormat('dd/MM/yy HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: materialColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            report.type == ReportType.criticalPoint
                ? Icons.warning_amber
                : Icons.recycling,
            color: materialColor,
            size: 22,
          ),
        ),
        title: Text(
          '${report.material} — ${report.type}',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Row(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                report.status,
                style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              fmt.format(report.timestamp),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (report.location.address != null)
                  _InfoRow(
                    icon: Icons.location_on,
                    text: report.location.address!,
                  ),
                _InfoRow(
                  icon: Icons.person,
                  text: 'Reportado por: ${report.reporterUserId}',
                ),
                if (report.assignedRecyclerId != null)
                  _InfoRow(
                    icon: Icons.assignment_ind,
                    text: 'Reciclador: ${report.assignedRecyclerId}',
                  ),
                if (report.description != null)
                  _InfoRow(
                    icon: Icons.notes,
                    text: report.description!,
                  ),
                const SizedBox(height: 12),
                _StatusActions(report: report),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: Colors.grey),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}

class _StatusActions extends ConsumerWidget {
  final Report report;
  const _StatusActions({required this.report});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(reportsNotifierProvider.notifier);

    return Wrap(
      spacing: 8,
      children: [
        if (!report.isPending)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.pending,
              side: const BorderSide(color: AppColors.pending),
            ),
            onPressed: () =>
                notifier.updateStatus(report.id, ReportStatus.pending),
            icon: const Icon(Icons.hourglass_empty, size: 16),
            label: const Text('Pendiente'),
          ),
        if (!report.isOnTheWay)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.onTheWay,
              side: const BorderSide(color: AppColors.onTheWay),
            ),
            onPressed: () =>
                notifier.updateStatus(report.id, ReportStatus.onTheWay),
            icon: const Icon(Icons.directions_bike, size: 16),
            label: const Text('En Camino'),
          ),
        if (!report.isCompleted)
          FilledButton.icon(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.completed),
            onPressed: () =>
                notifier.updateStatus(report.id, ReportStatus.completed),
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Completado'),
          ),
      ],
    );
  }
}
