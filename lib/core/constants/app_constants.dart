abstract class AppConstants {
  static const String appName = 'Master Ecology';
  static const String appVersion = '1.0.0';

  // Medellín center coordinates
  static const double medellinLat = 6.2442;
  static const double medellinLng = -75.5812;
  static const double defaultZoom = 13.0;

  // AWS future endpoints (placeholder)
  static const String apiBaseUrl = 'https://api.masterecology.co/v1';

  // Local storage keys
  static const String keyUserProfile = 'user_profile';
  static const String keyReports = 'cached_reports';
}

abstract class WasteMaterial {
  static const String carton = 'Cartón';
  static const String glass = 'Vidrio';
  static const String plastic = 'Plástico';
  static const String metal = 'Metal';
  static const String organic = 'Orgánico';
  static const String electronic = 'Electrónico';
  static const String textile = 'Textil';

  static const List<String> all = [
    carton,
    glass,
    plastic,
    metal,
    organic,
    electronic,
    textile,
  ];
}

abstract class ReportType {
  static const String criticalPoint = 'Punto Crítico';
  static const String collection = 'Recolección';

  static const List<String> all = [criticalPoint, collection];
}

abstract class ReportStatus {
  static const String pending = 'Pendiente';
  static const String onTheWay = 'En Camino';
  static const String completed = 'Completado';

  static const List<String> all = [pending, onTheWay, completed];
}

abstract class UserRole {
  static const String citizen = 'ciudadano';
  static const String recycler = 'reciclador';
  static const String admin = 'admin';
}
