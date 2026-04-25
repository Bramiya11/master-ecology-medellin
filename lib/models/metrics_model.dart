class ImpactMetrics {
  final int totalReports;
  final int completedReports;
  final double tonnesDeviated;
  final double co2SavedKg;
  final double routeHoursOptimized;
  final int criticalPointsPending;
  final Map<String, int> reportsByMaterial;
  final Map<String, int> reportsByStatus;

  const ImpactMetrics({
    required this.totalReports,
    required this.completedReports,
    required this.tonnesDeviated,
    required this.co2SavedKg,
    required this.routeHoursOptimized,
    required this.criticalPointsPending,
    required this.reportsByMaterial,
    required this.reportsByStatus,
  });

  double get completionRate =>
      totalReports == 0 ? 0 : completedReports / totalReports;
}
