import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options_prod.dart' as prod_options;
import 'main.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Production Firebase config
  await Firebase.initializeApp(
    options: prod_options.DefaultFirebaseOptions.currentPlatform,
  );

  // Common app ko launch karein
  runCommonApp('Prod');
}