import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnv {
  // Prefer runtime .env value (loaded in main), fall back to compile-time
  // environment and then to a safe default. Strip all whitespace to avoid
  // invalid URLs like `https:// example.com`.
  static String _raw =
      dotenv.env['BACKEND'] ??
      const String.fromEnvironment(
        'BACKEND',
        defaultValue: 'http://localhost:3030',
      );

  static final backendUrl = _raw.replaceAll(RegExp(r'\s+'), '').trim();
}
