import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/report_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reports_provider.dart';

class RecyclerRoutesScreen extends ConsumerWidget {
  const RecyclerRoutesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final reportsAsync = ref.watch(reportsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Rutas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(reportsNotifierProvider.notifier).refresh(),
          ),
        ],
      ),
      body: reportsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (reports) {
          final assigned = reports
              .where((r) => r.assignedRecyclerId == user?.id)
              .toList();
          final pending = reports.where((r) => r.isPending).toList();

          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: 'Asignados a mí'),
                    Tab(text: 'Disponibles'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _RouteList(
                        reports: assigned,
                        emptyMessage: 'No tienes rutas asignadas',
                        userId: user?.id ?? '',
                        showAssignButton: false,
                        ref: ref,
                      ),
                      _RouteList(
                        reports: pending,
                        emptyMessage: 'No hay reportes pendientes',
                        userId: user?.id ?? '',
                        showAssignButton: true,
                        ref: ref,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RouteList extends StatelessWidget {
  final List<Report> reports;
  final String emptyMessage;
  final String userId;
  final bool showAssignButton;
  final WidgetRef ref;

  const _RouteList({
    required this.reports,
    required this.emptyMessage,
    required this.userId,
    required this.showAssignButton,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(emptyMessage,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: reports.length,
      itemBuilder: (context, i) => _RouteCard(
        report: reports[i],
        userId: userId,
        showAssignButton: showAssignButton,
        ref: ref,
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  final Report report;
  final String userId;
  final bool showAssignButton;
  final WidgetRef ref;

  const _RouteCard({
    required this.report,
    required this.userId,
    required this.showAssignButton,
    required this.ref,
  });

  Color get _statusColor => switch (report.status) {
        ReportStatus.pending => AppColors.pending,
        ReportStatus.onTheWay => AppColors.onTheWay,
        _ => AppColors.completed,
      };

  @override
  Widget build(BuildContext context) {
    final materialColor =
        AppColors.materialColors[report.material] ?? AppColors.forestGreen;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: materialColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.recycling, color: materialColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.material,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        report.type,
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    report.status,
                    style: TextStyle(
                        color: _statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            if (report.location.address != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.location_on,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      report.location.address!,
                      style: const TextStyle(
                          fontSize: 13, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (report.description != null) ...[
              const SizedBox(height: 6),
              Text(report.description!,
                  style: const TextStyle(fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                if (showAssignButton)
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.techOrange),
                      onPressed: () => ref
                          .read(reportsNotifierProvider.notifier)
                          .assignRecycler(report.id, userId),
                      icon: const Icon(Icons.assignment_ind, size: 18),
                      label: const Text('Tomar ruta'),
                    ),
                  ),
                if (!showAssignButton && report.isOnTheWay) ...[
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.completed),
                      onPressed: () async {
                        await ref
                            .read(reportsNotifierProvider.notifier)
                            .updateStatus(report.id, ReportStatus.completed);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(Icons.recycling, color: Colors.white),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      '¡Ruta completada! Gracias por tu labor.',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: AppColors.completed,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Marcar completado'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
