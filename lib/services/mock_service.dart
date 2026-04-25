import 'package:uuid/uuid.dart';

import '../core/constants/app_constants.dart';
import '../models/metrics_model.dart';
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
      aiSeverity: 'CRÍTICO',
      aiRecommendation: 'Recolección urgente en menos de 24 horas',
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
      aiSeverity: 'CRÍTICO',
      aiRecommendation: 'Riesgo sanitario activo, atención inmediata requerida',
    ),
    Report(
      id: 'r-005',
      type: ReportType.collection,
      material: WasteMaterial.metal,
      location: const ReportLocation(lat: 6.2443, lng: -75.5751, address: 'Belén, Cra 80'),
      status: ReportStatus.pending,
      timestamp: DateTime(2024, 11, 20, 10, 0),
      reporterUserId: 'u-citizen-01',
      aiSeverity: 'MODERADO',
      aiRecommendation: 'Programar recolección en próximas 48 horas',
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

    // ── Datos sintéticos demo ─ Belén ─────────────────────────────────────────
    Report(
      id: 'r-b01',
      type: ReportType.criticalPoint,
      material: WasteMaterial.plastic,
      location: const ReportLocation(lat: 6.2342, lng: -75.5892, address: 'Belén, Calle 24'),
      status: ReportStatus.pending,
      timestamp: DateTime(2024, 11, 20, 6, 45),
      reporterUserId: 'u-citizen-01',
      description: 'Basura ordinaria acumulada en lote baldío',
    ),
    Report(
      id: 'r-b02',
      type: ReportType.collection,
      material: WasteMaterial.metal,
      location: const ReportLocation(lat: 6.2318, lng: -75.5846, address: 'Belén, Cra 76B'),
      status: ReportStatus.onTheWay,
      timestamp: DateTime(2024, 11, 20, 7, 20),
      reporterUserId: 'u-citizen-01',
      assignedRecyclerId: 'u-recycler-01',
    ),
    Report(
      id: 'r-b03',
      type: ReportType.criticalPoint,
      material: WasteMaterial.organic,
      location: const ReportLocation(lat: 6.2381, lng: -75.5921, address: 'Belén, Calle 28'),
      status: ReportStatus.pending,
      timestamp: DateTime(2024, 11, 20, 7, 50),
      reporterUserId: 'u-citizen-01',
      description: 'Residuos orgánicos expuestos, riesgo sanitario',
    ),
    Report(
      id: 'r-b04',
      type: ReportType.collection,
      material: WasteMaterial.glass,
      location: const ReportLocation(lat: 6.2295, lng: -75.5878, address: 'Belén, Cra 74A'),
      status: ReportStatus.onTheWay,
      timestamp: DateTime(2024, 11, 20, 8, 10),
      reporterUserId: 'u-citizen-01',
      assignedRecyclerId: 'u-recycler-01',
    ),
    Report(
      id: 'r-b05',
      type: ReportType.collection,
      material: WasteMaterial.carton,
      location: const ReportLocation(lat: 6.2362, lng: -75.5857, address: 'Belén, Calle 27A'),
      status: ReportStatus.pending,
      timestamp: DateTime(2024, 11, 20, 8, 30),
      reporterUserId: 'u-citizen-01',
      description: 'Cartón limpio de supermercado',
    ),

    // ── Datos sintéticos demo ─ Aranjuez ──────────────────────────────────────
    Report(
      id: 'r-a01',
      type: ReportType.criticalPoint,
      material: WasteMaterial.plastic,
      location: const ReportLocation(lat: 6.2753, lng: -75.5619, address: 'Aranjuez, Calle 93'),
      status: ReportStatus.pending,
      timestamp: DateTime(2024, 11, 20, 6, 30),
      reporterUserId: 'u-citizen-01',
      description: 'Basura ordinaria acumulada, requiere atención urgente',
    ),
    Report(
      id: 'r-a02',
      type: ReportType.collection,
      material: WasteMaterial.textile,
      location: const ReportLocation(lat: 6.2728, lng: -75.5643, address: 'Aranjuez, Cra 49'),
      status: ReportStatus.onTheWay,
      timestamp: DateTime(2024, 11, 20, 7, 15),
      reporterUserId: 'u-citizen-01',
      assignedRecyclerId: 'u-recycler-01',
    ),
    Report(
      id: 'r-a03',
      type: ReportType.criticalPoint,
      material: WasteMaterial.organic,
      location: const ReportLocation(lat: 6.2789, lng: -75.5598, address: 'Aranjuez, Calle 95'),
      status: ReportStatus.pending,
      timestamp: DateTime(2024, 11, 20, 7, 45),
      reporterUserId: 'u-citizen-01',
      description: 'Punto negro de basura en espacio público',
    ),
    Report(
      id: 'r-a04',
      type: ReportType.collection,
      material: WasteMaterial.metal,
      location: const ReportLocation(lat: 6.2712, lng: -75.5661, address: 'Aranjuez, Cra 51'),
      status: ReportStatus.pending,
      timestamp: DateTime(2024, 11, 20, 9, 0),
      reporterUserId: 'u-citizen-01',
    ),
    Report(
      id: 'r-a05',
      type: ReportType.collection,
      material: WasteMaterial.glass,
      location: const ReportLocation(lat: 6.2771, lng: -75.5623, address: 'Aranjuez, Calle 90'),
      status: ReportStatus.onTheWay,
      timestamp: DateTime(2024, 11, 20, 10, 30),
      reporterUserId: 'u-citizen-01',
      assignedRecyclerId: 'u-recycler-01',
    ),

    // ── Datos sintéticos demo ─ El Poblado ────────────────────────────────────
    Report(
      id: 'r-p01',
      type: ReportType.criticalPoint,
      material: WasteMaterial.plastic,
      location: const ReportLocation(lat: 6.2112, lng: -75.5664, address: 'El Poblado, Cra 43A'),
      status: ReportStatus.pending,
      timestamp: DateTime(2024, 11, 20, 6, 0),
      reporterUserId: 'u-citizen-01',
      description: 'Basura ordinaria acumulada frente a parque',
    ),
    Report(
      id: 'r-p02',
      type: ReportType.collection,
      material: WasteMaterial.glass,
      location: const ReportLocation(lat: 6.2145, lng: -75.5641, address: 'El Poblado, Calle 16'),
      status: ReportStatus.onTheWay,
      timestamp: DateTime(2024, 11, 20, 7, 0),
      reporterUserId: 'u-citizen-01',
      assignedRecyclerId: 'u-recycler-01',
    ),
    Report(
      id: 'r-p03',
      type: ReportType.criticalPoint,
      material: WasteMaterial.metal,
      location: const ReportLocation(lat: 6.2091, lng: -75.5683, address: 'El Poblado, Cra 42'),
      status: ReportStatus.pending,
      timestamp: DateTime(2024, 11, 20, 8, 0),
      reporterUserId: 'u-citizen-01',
      description: 'Chatarra y residuos metálicos en vía pública',
    ),
    Report(
      id: 'r-p04',
      type: ReportType.collection,
      material: WasteMaterial.carton,
      location: const ReportLocation(lat: 6.2168, lng: -75.5622, address: 'El Poblado, Calle 10A'),
      status: ReportStatus.onTheWay,
      timestamp: DateTime(2024, 11, 20, 9, 30),
      reporterUserId: 'u-citizen-01',
      assignedRecyclerId: 'u-recycler-01',
    ),
    Report(
      id: 'r-p05',
      type: ReportType.collection,
      material: WasteMaterial.electronic,
      location: const ReportLocation(lat: 6.2134, lng: -75.5658, address: 'El Poblado, Cra 43'),
      status: ReportStatus.pending,
      timestamp: DateTime(2024, 11, 20, 11, 0),
      reporterUserId: 'u-citizen-01',
      description: 'Electrodomésticos obsoletos para reciclar',
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
    String? aiSeverity,
    String? aiRecommendation,
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
      aiSeverity: aiSeverity,
      aiRecommendation: aiRecommendation,
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
    final criticalPending = _reports
        .where((r) => r.type == ReportType.criticalPoint && r.isPending)
        .length;
    return ImpactMetrics(
      totalReports: _reports.length,
      completedReports: completed,
      // Each completed report ≈ 12 kg diverted
      tonnesDeviated: (completed * 12) / 1000,
      // CO2: 2.5 kg CO2 per kg of recycled material
      co2SavedKg: completed * 12 * 2.5,
      // 15 min (0.25 hr) of optimized route per completed nearby report
      routeHoursOptimized: completed * 0.25,
      criticalPointsPending: criticalPending,
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

