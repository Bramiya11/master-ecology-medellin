import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/mock_service.dart';
import 'reports_provider.dart';

final metricsProvider = FutureProvider<ImpactMetrics>((ref) async {
  ref.watch(reportsNotifierProvider);
  return MockService.instance.fetchImpactMetrics();
});
