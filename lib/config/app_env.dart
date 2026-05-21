import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnv {
  static String get backendUrl {
    final value = dotenv.env['BACKEND']?.trim();
    if (value == null || value.isEmpty) {
      throw StateError('BACKEND is missing from .env');
    }
    return value;
  }
}
