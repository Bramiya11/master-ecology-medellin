import 'dart:convert';

import '../../amplifyconfiguration.dart';
import 'ai_secrets.dart';

class AwsConfig {
  static final Map<String, dynamic> _api =
      (jsonDecode(amplifyconfig) as Map<String, dynamic>)['api']['plugins']
          ['awsAPIPlugin']['masterecologyapi'] as Map<String, dynamic>;

  static String get endpoint => _api['endpoint'] as String;
  static String get apiKey => _api['apiKey'] as String;

  // ── AI Lambda endpoints via API Gateway ───────────────────────────────────
  // Valores en ai_secrets.dart (gitignoreado). Ver ai_secrets.dart.example.
  static const String _aiApiBase = kAiApiBase;
  static const String aiApiKey   = kAiApiKey;

  static String get analyzePhotoUrl => '$_aiApiBase/analyze-photo';
  static String get generateEcoInsightUrl => '$_aiApiBase/generate-eco-insight';

  // ── S3 ────────────────────────────────────────────────────────────────────
  static final Map<String, dynamic> _storage =
      (jsonDecode(amplifyconfig) as Map<String, dynamic>)['storage']['plugins']
          ['awsS3StoragePlugin'] as Map<String, dynamic>;

  static String get s3Bucket => _storage['bucket'] as String;
  static String get awsRegion => _storage['region'] as String;
}
