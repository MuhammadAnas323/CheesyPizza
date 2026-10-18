import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart' as dev_options;
import 'main.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Dev Firebase config
  await Firebase.initializeApp(
    options: dev_options.DefaultFirebaseOptions.currentPlatform,
  );

  // Common app ko launch karein
  runCommonApp('Dev');
}