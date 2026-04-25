import 'dart:convert';
import 'dart:typed_data';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../core/config/aws_config.dart';
import '../core/constants/app_constants.dart';
import '../models/metrics_model.dart';
import '../models/report_model.dart';
import '../models/user_model.dart';

const _uuid = Uuid();

class AmplifyService {
  AmplifyService._();
  static final AmplifyService instance = AmplifyService._();

  late final Dio _dio = Dio(
    BaseOptions(
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': AwsConfig.apiKey,
      },
    ),
  );

  late final Dio _aiDio = Dio(
    BaseOptions(
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': AwsConfig.aiApiKey,
      },
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;

  // ── Auth demo ─────────────────────────────────────────────────────────────

  Future<AppUser> loginAsRole(String role) async {
    const users = {
      UserRole.citizen: ('u-citizen-01', 'Ana García', 'ana@masterecology.co'),
      UserRole.recycler:
          ('u-recycler-01', 'Carlos Ruiz', 'carlos@masterecology.co'),
      UserRole.admin:
          ('u-admin-01', 'Laura Mendoza', 'laura@masterecology.co'),
    };
    final (id, name, email) = users[role]!;
    _currentUser = AppUser(
      id: id,
      name: name,
      email: email,
      role: role,
      createdAt: DateTime(2024, 1, 1),
    );
    return _currentUser!;
  }

  Future<void> logout() async => _currentUser = null;

  // ── GraphQL helper ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _gql(
    String query, [
    Map<String, dynamic>? variables,
  ]) async {
    final res = await _dio.post<Map<String, dynamic>>(
      AwsConfig.endpoint,
      data: jsonEncode({
        'query': query,
        if (variables != null) 'variables': variables,
      }),
    );
    final body = res.data!;
    final errors = body['errors'];
    if (errors != null && (errors as List).isNotEmpty) {
      throw Exception((errors.first as Map)['message']);
    }
    return body['data'] as Map<String, dynamic>;
  }

  // ── GraphQL documents ─────────────────────────────────────────────────────

  static const _listReports = r'''
    query ListReports {
      listReports {
        items {
          id type material lat lng address
          photoUrl status timestamp
          reporterUserId description assignedRecyclerId
          aiSeverity aiRecommendation
        }
      }
    }
  ''';

  static const _createReportMutation = r'''
    mutation CreateReport($input: CreateReportInput!) {
      createReport(input: $input) {
        id type material lat lng address
        photoUrl status timestamp
        reporterUserId description assignedRecyclerId
        aiSeverity aiRecommendation
      }
    }
  ''';

  static const _updateReportMutation = r'''
    mutation UpdateReport($input: UpdateReportInput!) {
      updateReport(input: $input) {
        id type material lat lng address
        photoUrl status timestamp
        reporterUserId description assignedRecyclerId
        aiSeverity aiRecommendation
      }
    }
  ''';

  // ── Helpers ───────────────────────────────────────────────────────────────

  Report _parseReport(Map<String, dynamic> item) => Report(
        id: item['id'] as String,
        type: item['type'] as String,
        material: item['material'] as String,
        location: ReportLocation(
          lat: (item['lat'] as num).toDouble(),
          lng: (item['lng'] as num).toDouble(),
          address: item['address'] as String?,
        ),
        photoUrl: item['photoUrl'] as String?,
        status: item['status'] as String,
        timestamp: DateTime.parse(item['timestamp'] as String),
        reporterUserId: item['reporterUserId'] as String,
        description: item['description'] as String?,
        assignedRecyclerId: item['assignedRecyclerId'] as String?,
        aiSeverity: item['aiSeverity'] as String?,
        aiRecommendation: item['aiRecommendation'] as String?,
      );

  // ── Reports CRUD ──────────────────────────────────────────────────────────

  Future<List<Report>> fetchReports() async {
    final data = await _gql(_listReports);
    final items =
        (data['listReports']['items'] as List).cast<Map<String, dynamic>>();
    return items.map(_parseReport).toList();
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
    final input = <String, dynamic>{
      'id': 'r-${_uuid.v4().substring(0, 8)}',
      'type': type,
      'material': material,
      'lat': location.lat,
      'lng': location.lng,
      if (location.address != null) 'address': location.address,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'status': ReportStatus.pending,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'reporterUserId': _currentUser?.id ?? 'anonymous',
      if (description != null) 'description': description,
      if (aiSeverity != null) 'aiSeverity': aiSeverity,
      if (aiRecommendation != null) 'aiRecommendation': aiRecommendation,
    };
    final data = await _gql(_createReportMutation, {'input': input});
    return _parseReport(data['createReport'] as Map<String, dynamic>);
  }

  Future<Report> updateReportStatus(String reportId, String newStatus) async {
    final data = await _gql(_updateReportMutation, {
      'input': {'id': reportId, 'status': newStatus},
    });
    return _parseReport(data['updateReport'] as Map<String, dynamic>);
  }

  Future<Report> assignRecycler(String reportId, String recyclerId) async {
    final data = await _gql(_updateReportMutation, {
      'input': {
        'id': reportId,
        'assignedRecyclerId': recyclerId,
        'status': ReportStatus.onTheWay,
      },
    });
    return _parseReport(data['updateReport'] as Map<String, dynamic>);
  }

  // ── Métricas ──────────────────────────────────────────────────────────────

  Future<ImpactMetrics> fetchImpactMetrics() async {
    final reports = await fetchReports();
    final completed = reports.where((r) => r.isCompleted).length;
    final criticalPending = reports
        .where((r) => r.type == ReportType.criticalPoint && r.isPending)
        .length;

    final byMaterial = <String, int>{};
    final byStatus = <String, int>{};
    for (final r in reports) {
      byMaterial[r.material] = (byMaterial[r.material] ?? 0) + 1;
      byStatus[r.status] = (byStatus[r.status] ?? 0) + 1;
    }

    return ImpactMetrics(
      totalReports: reports.length,
      completedReports: completed,
      tonnesDeviated: (completed * 12) / 1000,
      co2SavedKg: completed * 12 * 2.5,
      routeHoursOptimized: completed * 0.25,
      criticalPointsPending: criticalPending,
      reportsByMaterial: byMaterial,
      reportsByStatus: byStatus,
    );
  }

  Future<List<Report>> fetchAssignedReports(String recyclerId) async {
    final all = await fetchReports();
    return all.where((r) => r.assignedRecyclerId == recyclerId).toList();
  }

  Future<List<Report>> fetchPendingReports() async {
    final all = await fetchReports();
    return all.where((r) => r.isPending).toList();
  }

  // ── Photo upload ──────────────────────────────────────────────────────────

  Future<String> uploadPhoto(Uint8List bytes, String filename) async {
    final s3Key = 'public/photos/$filename';
    await Amplify.Storage.uploadData(
      path: StoragePath.fromString(s3Key),
      data: StorageDataPayload.bytes(bytes, contentType: 'image/jpeg'),
    ).result;
    return s3Key;
  }

  // ── AI: Rekognition + clasificación foto ─────────────────────────────────

  Future<({String severity, String recommendation, List<String> labels})>
      analyzePhoto(String s3Key) async {
    final res = await _aiDio.post<Map<String, dynamic>>(
      AwsConfig.analyzePhotoUrl,
      data: jsonEncode({'s3Key': s3Key, 'bucket': AwsConfig.s3Bucket}),
    );
    final body = _unwrapLambdaBody(res.data!);
    return (
      severity: body['severity'] as String? ?? 'MODERADO',
      recommendation:
          body['recommendation'] as String? ?? 'Revisar y clasificar residuos',
      labels: (body['labels'] as List?)?.cast<String>() ?? [],
    );
  }

  // ── AI: Insight ejecutivo para admin ──────────────────────────────────────

  Future<String> generateEcoInsight(ImpactMetrics metrics) async {
    final res = await _aiDio.post<Map<String, dynamic>>(
      AwsConfig.generateEcoInsightUrl,
      data: jsonEncode({
        'metrics': {
          'totalReports': metrics.totalReports,
          'completedReports': metrics.completedReports,
          'tonnesDeviated': metrics.tonnesDeviated,
          'co2SavedKg': metrics.co2SavedKg,
          'completionRate': metrics.completionRate,
          'criticalPointsPending': metrics.criticalPointsPending,
          'routeHoursOptimized': metrics.routeHoursOptimized,
        },
      }),
    );
    final body = _unwrapLambdaBody(res.data!);
    return body['insight'] as String? ??
        'No se pudo generar el análisis en este momento.';
  }

  // Maneja tanto Lambda proxy integration (body directo) como non-proxy
  // (donde API Gateway devuelve {statusCode, headers, body: "string json"})
  Map<String, dynamic> _unwrapLambdaBody(Map<String, dynamic> response) {
    final rawBody = response['body'];
    if (rawBody is String) {
      return jsonDecode(rawBody) as Map<String, dynamic>;
    }
    return response;
  }
}
