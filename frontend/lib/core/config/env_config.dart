import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get apiBaseUrl {
    final url = dotenv.env['API_BASE_URL'] ?? (kIsWeb ? 'http://localhost:8000' : 'http://10.0.2.2:8000');
    if (kIsWeb && url.contains('10.0.2.2')) {
      return url.replaceAll('10.0.2.2', 'localhost');
    }
    return url;
  }

  static String get wsBaseUrl {
    final url = dotenv.env['WS_BASE_URL'] ?? (kIsWeb ? 'ws://localhost:8000/ws' : 'ws://10.0.2.2:8000/ws');
    if (kIsWeb && url.contains('10.0.2.2')) {
      return url.replaceAll('10.0.2.2', 'localhost');
    }
    return url;
  }

  static String get appEnv =>
      dotenv.env['APP_ENV'] ?? 'development';

  static bool get isDevelopment => appEnv == 'development';
}
