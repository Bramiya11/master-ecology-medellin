import 'package:uuid/uuid.dart';

import '../core/constants/app_constants.dart';
import '../models/report_model.dart';
import '../models/user_model.dart';

// Simulates AWS DynamoDB async latency
const _kFakeDelay = Duration(milliseconds: 400);
const _uuid = Uuid();

class MockService {
  MockService._();
  static final MockService instance = MockService._();

  // ── Seed users ──────────────────────────────────────────────────────────────

  final List<AppUser> _users = [
    AppUser(
      id: 'u-citizen-01',
      name: 'Ana García',
      email: 'ana@example.com',
      role: UserRole.citizen,
      createdAt: DateTime(2024, 1, 15),
    ),
    AppUser(
      id: 'u-recycler-01',
      name: 'Carlos Ruiz',
      email: 'carlos@example.com',
      role: UserRole.recycler,
      createdAt: DateTime(2024, 2, 3),
    ),
    AppUser(
      id: 'u-admin-01',
      name: 'Laura Mendoza',
      email: 'laura@example.com',
      role: UserRole.admin,
      createdAt: DateTime(2024, 1, 1),
    ),
  ];

  // ── Seed reports (Medellín neighborhoods) ──────────────────────────────────

  final List<Report> _reports = [
    Report(
      id: 'r-001',
      type: ReportType.criticalPoint,
      material: WasteMaterial.plastic,
      location: const ReportLocation(lat: 6.2519, lng: -75.5636, address: 'El Poblado, Calle 10'),
      status: ReportStatus.pending,
      timestamp: DateTime(2024, 11, 20, 8, 30),
      reporterUserId: 'u-citizen-01',
      description: 'Acumulación de bolsas plásticas en la esquina',
    ),
    Report(
      id: 'r-002',
      type: ReportType.collection,
      material: WasteMaterial.carton,
      location: const ReportLocation(lat: 6.2320, lng: -75.5741, address: 'Laureles, Cra 76'),
      status: ReportStatus.onTheWay,
      timestamp: DateTime(2024, 11, 20, 9, 15),
      reporterUserId: 'u-citizen-01',
      assignedRecyclerId: 'u-recycler-01',
      description: 'Cajas de cartón limpias para recolección',
    ),
    Report(
      id: 'r-003',
      type: ReportType.collection,
      material: WasteMaterial.glass,
      location: const ReportLocation(lat: 6.2671, lng: -75.5673, address: 'Envigado, Calle 39S'),
      status: ReportStatus.completed,
      timestamp: DateTime(2024, 11, 19, 14, 0),
      reporterUserId: 'u-citizen-01',
      assignedRecyclerId: 'u-recycler-01',
    ),
    Report(
      id: 'r-004',
      type: ReportType.criticalPoint,
      material: WasteMaterial.organic,
      location: const ReportLocation(lat: 6.2738, lng: -75.5611, address: 'Aranjuez, Calle 93'),
      status: ReportStatus.pending,
      timestamp: DateTime(2024, 11, 20, 7, 45),
      reporterUserId: 'u-citizen-01',
      description: 'Residuos orgánicos expuestos en vía pública',
    ),
    Report(
      id: 'r-005',
      type: ReportType.collection,
      material: WasteMaterial.metal,
      location: const ReportLocation(lat: 6.2443, lng: -75.5751, address: 'Belén, Cra 80'),
      status: ReportStatus.pending,
      timestamp: DateTime(2024, 11, 20, 10, 0),
      reporterUserId: 'u-citizen-01',
    ),
    Report(
      id: 'r-006',
      type: ReportType.collection,
      material: WasteMaterial.electronic,
      location: const ReportLocation(lat: 6.2600, lng: -75.5680, address: 'Estadio, Calle 48'),
      status: ReportStatus.onTheWay,
      timestamp: DateTime(2024, 11, 20, 11, 30),
      reporterUserId: 'u-citizen-01',
      assignedRecyclerId: 'u-recycler-01',
      description: 'Computador viejo y electrodomésticos menores',
    ),
    Report(
      id: 'r-007',
      type: ReportType.criticalPoint,
      material: WasteMaterial.plastic,
      location: const ReportLocation(lat: 6.2350, lng: -75.5800, address: 'Robledo, Calle 105'),
      status: ReportStatus.completed,
      timestamp: DateTime(2024, 11, 18, 16, 20),
      reporterUserId: 'u-citizen-01',
    ),
    Report(
      id: 'r-008',
      type: ReportType.collection,
      material: WasteMaterial.textile,
      location: const ReportLocation(lat: 6.2480, lng: -75.5720, address: 'La América, Cra 65'),
      status: ReportStatus.pending,
      timestamp: DateTime(2024, 11, 20, 13, 0),
      reporterUserId: 'u-citizen-01',
      description: 'Ropa y textiles en buen estado para donación',
    ),
  ];

  // ── Auth simulation ──────────────────────────────────────────────────────────

  AppUser? _currentUser;

  Future<AppUser?> login(String email) async {
    await Future.delayed(_kFakeDelay);
    _currentUser = _users.firstWhere(
      (u) => u.email == email,
      orElse: () => _users.first,
    );
    return _currentUser;
  }

  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _currentUser = null;
  }

  AppUser? get currentUser => _currentUser;

  // Demo: login instantly as a role
  Future<AppUser> loginAsRole(String role) async {
    await Future.delayed(_kFakeDelay);
    _currentUser = _users.firstWhere((u) => u.role == role);
    return _currentUser!;
  }

  // ── Reports CRUD ─────────────────────────────────────────────────────────────

  Future<List<Report>> fetchReports() async {
    await Future.delayed(_kFakeDelay);
    return List.unmodifiable(_reports);
  }

  Future<Report> createReport({
    required String type,
    required String material,
    required ReportLocation location,
    String? photoUrl,
    String? description,
  }) async {
    await Future.delayed(_kFakeDelay);
    final report = Report(
      id: 'r-${_uuid.v4().substring(0, 8)}',
      type: type,
      material: material,
      location: location,
      photoUrl: photoUrl,
      status: ReportStatus.pending,
      timestamp: DateTime.now(),
      reporterUserId: _currentUser?.id ?? 'anonymous',
      description: description,
    );
    _reports.add(report);
    return report;
  }

  Future<Report> updateReportStatus(String reportId, String newStatus) async {
    await Future.delayed(_kFakeDelay);
    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index == -1) throw Exception('Reporte no encontrado: $reportId');
    final updated = _reports[index].copyWith(status: newStatus);
    _reports[index] = updated;
    return updated;
  }

  Future<Report> assignRecycler(String reportId, String recyclerId) async {
    await Future.delayed(_kFakeDelay);
    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index == -1) throw Exception('Reporte no encontrado: $reportId');
    final updated = _reports[index].copyWith(
      assignedRecyclerId: recyclerId,
      status: ReportStatus.onTheWay,
    );
    _reports[index] = updated;
    return updated;
  }

  // ── Impact metrics ───────────────────────────────────────────────────────────

  Future<ImpactMetrics> fetchImpactMetrics() async {
    await Future.delayed(_kFakeDelay);
    final completed = _reports.where((r) => r.isCompleted).length;
    return ImpactMetrics(
      totalReports: _reports.length,
      completedReports: completed,
      // Each completed report = ~12kg diverted on average
      tonnesDeviated: (completed * 12) / 1000,
      // CO2 savings: ~2.5kg CO2 per kg of recycled material
      co2SavedKg: completed * 12 * 2.5,
      reportsByMaterial: _computeByMaterial(),
      reportsByStatus: _computeByStatus(),
    );
  }

  Map<String, int> _computeByMaterial() {
    final map = <String, int>{};
    for (final r in _reports) {
      map[r.material] = (map[r.material] ?? 0) + 1;
    }
    return map;
  }

  Map<String, int> _computeByStatus() {
    final map = <String, int>{};
    for (final r in _reports) {
      map[r.status] = (map[r.status] ?? 0) + 1;
    }
    return map;
  }

  // ── Recycler routes ──────────────────────────────────────────────────────────

  Future<List<Report>> fetchAssignedReports(String recyclerId) async {
    await Future.delayed(_kFakeDelay);
    return _reports.where((r) => r.assignedRecyclerId == recyclerId).toList();
  }

  Future<List<Report>> fetchPendingReports() async {
    await Future.delayed(_kFakeDelay);
    return _reports.where((r) => r.isPending).toList();
  }
}

class ImpactMetrics {
  final int totalReports;
  final int completedReports;
  final double tonnesDeviated;
  final double co2SavedKg;
  final Map<String, int> reportsByMaterial;
  final Map<String, int> reportsByStatus;

  const ImpactMetrics({
    required this.totalReports,
    required this.completedReports,
    required this.tonnesDeviated,
    required this.co2SavedKg,
    required this.reportsByMaterial,
    required this.reportsByStatus,
  });

  double get completionRate =>
      totalReports == 0 ? 0 : completedReports / totalReports;
}
