import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'app/index.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    usePathUrlStrategy();
  }
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('[Main] Notice: .env file could not be loaded ($e), falling back to defaults.');
  }
  runApp(const App());
}
