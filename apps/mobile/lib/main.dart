import 'package:flutter/material.dart';
import 'package:nia_flutter/app/dependencies.dart';
import 'package:nia_flutter/app/nia_app.dart';
import 'package:nia_flutter/config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();
  final dependencies = await AppDependencies.bootstrap(config);
  runApp(NiaApp(dependencies: dependencies));
}
