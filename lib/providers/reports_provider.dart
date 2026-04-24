import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/report_model.dart';
import '../services/mock_service.dart';

// ── Filter state ─────────────────────────────────────────────────────────────

class ReportFilter {
  final Set<String> types;
  final Set<String> statuses;
  final Set<String> materials;

  const ReportFilter({
    this.types = const {},
    this.statuses = const {},
    this.materials = const {},
  });

  bool get hasActiveFilters =>
      types.isNotEmpty || statuses.isNotEmpty || materials.isNotEmpty;

  ReportFilter copyWith({
    Set<String>? types,
    Set<String>? statuses,
    Set<String>? materials,
  }) {
    return ReportFilter(
      types: types ?? this.types,
      statuses: statuses ?? this.statuses,
      materials: materials ?? this.materials,
    );
  }

  bool matches(Report r) {
    if (types.isNotEmpty && !types.contains(r.type)) return false;
    if (statuses.isNotEmpty && !statuses.contains(r.status)) return false;
    if (materials.isNotEmpty && !materials.contains(r.material)) return false;
    return true;
  }
}

class FilterNotifier extends StateNotifier<ReportFilter> {
  FilterNotifier() : super(const ReportFilter());

  void toggleType(String type) {
    final updated = Set<String>.from(state.types);
    updated.contains(type) ? updated.remove(type) : updated.add(type);
    state = state.copyWith(types: updated);
  }

  void toggleStatus(String status) {
    final updated = Set<String>.from(state.statuses);
    updated.contains(status) ? updated.remove(status) : updated.add(status);
    state = state.copyWith(statuses: updated);
  }

  void toggleMaterial(String material) {
    final updated = Set<String>.from(state.materials);
    updated.contains(material) ? updated.remove(material) : updated.add(material);
    state = state.copyWith(materials: updated);
  }

  void clearAll() => state = const ReportFilter();
}

final filterProvider = StateNotifierProvider<FilterNotifier, ReportFilter>(
  (ref) => FilterNotifier(),
);

// ── Reports async ─────────────────────────────────────────────────────────────

final reportsProvider = FutureProvider<List<Report>>((ref) async {
  return MockService.instance.fetchReports();
});

final filteredReportsProvider = Provider<AsyncValue<List<Report>>>((ref) {
  final reportsAsync = ref.watch(reportsProvider);
  final filter = ref.watch(filterProvider);

  return reportsAsync.whenData(
    (reports) => filter.hasActiveFilters
        ? reports.where(filter.matches).toList()
        : reports,
  );
});

// ── Mutations ─────────────────────────────────────────────────────────────────

class ReportsNotifier extends StateNotifier<AsyncValue<List<Report>>> {
  ReportsNotifier() : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    state = const AsyncValue.loading();
    try {
      final data = await MockService.instance.fetchReports();
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => _load();

  Future<void> createReport({
    required String type,
    required String material,
    required ReportLocation location,
    String? photoUrl,
    String? description,
  }) async {
    final prev = state;
    try {
      final newReport = await MockService.instance.createReport(
        type: type,
        material: material,
        location: location,
        photoUrl: photoUrl,
        description: description,
      );
      state = prev.whenData((list) => [newReport, ...list]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateStatus(String reportId, String newStatus) async {
    final updated = await MockService.instance.updateReportStatus(reportId, newStatus);
    state = state.whenData(
      (list) => list.map((r) => r.id == reportId ? updated : r).toList(),
    );
  }

  Future<void> assignRecycler(String reportId, String recyclerId) async {
    final updated = await MockService.instance.assignRecycler(reportId, recyclerId);
    state = state.whenData(
      (list) => list.map((r) => r.id == reportId ? updated : r).toList(),
    );
  }
}

final reportsNotifierProvider =
    StateNotifierProvider<ReportsNotifier, AsyncValue<List<Report>>>(
  (ref) => ReportsNotifier(),
);
