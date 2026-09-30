import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000';

  static String get wsBaseUrl =>
      dotenv.env['WS_BASE_URL'] ?? 'ws://10.0.2.2:8000/ws';

  static String get appEnv =>
      dotenv.env['APP_ENV'] ?? 'development';

  static bool get isDevelopment => appEnv == 'development';
}
