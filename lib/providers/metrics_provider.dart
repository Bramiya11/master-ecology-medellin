import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../amplifyconfiguration.dart';
import '../models/metrics_model.dart';
import '../services/amplify_service.dart';
import '../services/mock_service.dart';
import 'reports_provider.dart';

final metricsProvider = FutureProvider<ImpactMetrics>((ref) async {
  ref.watch(reportsNotifierProvider);
  return kAmplifyConfigured
      ? AmplifyService.instance.fetchImpactMetrics()
      : MockService.instance.fetchImpactMetrics();
});
