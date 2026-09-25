import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';
import 'services/app_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = await AppController.create();
  runApp(RaicesApp(controller: controller));
  unawaited(controller.init());
}
