import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/report_model.dart';
import '../../providers/reports_provider.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _mapController = MapController();
  Report? _selectedReport;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(filteredReportsProvider);
    final filter = ref.watch(filterProvider);

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(
                AppConstants.medellinLat,
                AppConstants.medellinLng,
              ),
              initialZoom: AppConstants.defaultZoom,
              onTap: (_, __) => setState(() => _selectedReport = null),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'co.masterecology.app',
                maxZoom: 19,
              ),
              reportsAsync.when(
                data: (reports) => MarkerLayer(
                  markers: reports.map(_buildMarker).toList(),
                ),
                loading: () => const MarkerLayer(markers: []),
                error: (_, __) => const MarkerLayer(markers: []),
              ),
            ],
          ),

          // Filter chips
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            right: 8,
            child: _FilterBar(filter: filter),
          ),

          // Report detail card
          if (_selectedReport != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: _ReportCard(
                report: _selectedReport!,
                onClose: () => setState(() => _selectedReport = null),
              ),
            ),

          // Loading overlay
          if (reportsAsync.isLoading)
            const Positioned(
              top: 80,
              right: 16,
              child: CircularProgressIndicator(),
            ),

          // Critical points alert badge
          Builder(builder: (context) {
            final criticalCount = reportsAsync.valueOrNull
                    ?.where((r) =>
                        r.type == ReportType.criticalPoint && r.isPending)
                    .length ??
                0;
            if (criticalCount == 0) return const SizedBox.shrink();
            return Positioned(
              top: MediaQuery.of(context).padding.top + 64,
              right: 12,
              child: _CriticalAlertBadge(count: criticalCount),
            );
          }),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/citizen/report'),
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Reportar'),
        backgroundColor: AppColors.techOrange,
        foregroundColor: Colors.white,
      ),
    );
  }

  Marker _buildMarker(Report report) {
    final color = AppColors.materialColors[report.material] ??
        AppColors.forestGreen;
    final isSelected = _selectedReport?.id == report.id;

    if (report.type == ReportType.criticalPoint) {
      return Marker(
        point: report.location.toLatLng(),
        // Extra bounds to avoid clipping during scale animation
        width: isSelected ? 56 : 44,
        height: isSelected ? 56 : 44,
        child: _PulsingCriticalMarker(
          isSelected: isSelected,
          onTap: () => setState(() => _selectedReport = report),
        ),
      );
    }

    return Marker(
      point: report.location.toLatLng(),
      width: isSelected ? 48 : 36,
      height: isSelected ? 48 : 36,
      child: GestureDetector(
        onTap: () => setState(() => _selectedReport = report),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? Colors.white : Colors.transparent,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: isSelected ? 12 : 6,
                spreadRadius: isSelected ? 2 : 0,
              ),
            ],
          ),
          child: Icon(
            Icons.recycling,
            color: Colors.white,
            size: isSelected ? 26 : 20,
          ),
        ),
      ),
    );
  }
}

class _FilterBar extends ConsumerWidget {
  final ReportFilter filter;
  const _FilterBar({required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(filterProvider.notifier);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...ReportType.all.map(
            (type) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                label: Text(type),
                selected: filter.types.contains(type),
                onSelected: (_) => notifier.toggleType(type),
                backgroundColor: Colors.white,
                selectedColor: AppColors.forestGreenLight.withValues(alpha: 0.3),
              ),
            ),
          ),
          ...WasteMaterial.all.map(
            (m) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                label: Text(m),
                selected: filter.materials.contains(m),
                onSelected: (_) => notifier.toggleMaterial(m),
                backgroundColor: Colors.white,
                selectedColor:
                    (AppColors.materialColors[m] ?? AppColors.forestGreen)
                        .withValues(alpha: 0.3),
              ),
            ),
          ),
          if (filter.hasActiveFilters)
            ActionChip(
              label: const Text('Limpiar'),
              avatar: const Icon(Icons.clear, size: 16),
              onPressed: notifier.clearAll,
            ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final Report report;
  final VoidCallback onClose;

  const _ReportCard({required this.report, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = switch (report.status) {
      ReportStatus.pending => AppColors.pending,
      ReportStatus.onTheWay => AppColors.onTheWay,
      _ => AppColors.completed,
    };
    final materialColor =
        AppColors.materialColors[report.material] ?? AppColors.forestGreen;

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: materialColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: materialColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    report.material,
                    style: TextStyle(
                      color: materialColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    report.status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              report.type,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (report.location.address != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      report.location.address!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            if (report.description != null) ...[
              const SizedBox(height: 8),
              Text(
                report.description!,
                style: theme.textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Pulsing marker for critical points ───────────────────────────────────────

class _PulsingCriticalMarker extends StatefulWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const _PulsingCriticalMarker({required this.isSelected, required this.onTap});

  @override
  State<_PulsingCriticalMarker> createState() => _PulsingCriticalMarkerState();
}

class _PulsingCriticalMarkerState extends State<_PulsingCriticalMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.isSelected ? 40.0 : 30.0;
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.red.shade700,
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.isSelected ? Colors.white : Colors.orange.shade300,
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.55),
                blurRadius: widget.isSelected ? 14 : 8,
                spreadRadius: widget.isSelected ? 3 : 1,
              ),
            ],
          ),
          child: Icon(
            Icons.warning_amber,
            color: Colors.white,
            size: widget.isSelected ? 22 : 16,
          ),
        ),
      ),
    );
  }
}

// ── Floating badge that suggests alerting the waste company ──────────────────

class _CriticalAlertBadge extends StatelessWidget {
  final int count;
  const _CriticalAlertBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final label = '$count crítico${count > 1 ? 's' : ''}';
    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$count punto${count > 1 ? 's' : ''} crítico${count > 1 ? 's' : ''} '
            'detectado${count > 1 ? 's' : ''}. '
            'Alertando a empresa de aseo...',
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade700,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber, color: Colors.white, size: 15),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
