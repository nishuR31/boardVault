import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnv {
  // Prefer runtime .env value (loaded in main), fall back to compile-time
  // environment and then to a safe default. Strip all whitespace and trailing slashes.
  static String get backendUrl {
    final raw = dotenv.env['BACKEND'] ??
        const String.fromEnvironment(
          'BACKEND',
          defaultValue: 'https://boardvault-qq02.onrender.com',
        );
    final clean = raw.replaceAll(RegExp(r'\s+'), '').trim();
    return clean.endsWith('/') ? clean.substring(0, clean.length - 1) : clean;
  }
}
