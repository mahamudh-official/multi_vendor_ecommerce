import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';
import 'core/di/injection_container.dart';

Future<void> main() async {
  // Ensure Flutter bindings are initialized before async work
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait (unlock in Step 2+ if needed for tablet)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configure status bar transparency
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  // Initialize dependency injection
  await configureDependencies();

  runApp(const MarketoApp());
}
