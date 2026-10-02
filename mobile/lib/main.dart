import 'package:flutter/material.dart';
import 'package:tourkare/firebase_options.dart';
import 'package:tourkare/screens/auth/auth_gate.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'package:sqflite/sqflite.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  databaseFactory = databaseFactoryFfiWeb;

  runApp(const TourKareApp());
}

class TourKareApp extends StatelessWidget {
  const TourKareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TourKare',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: .fromSeed(
          seedColor: const Color.fromARGB(255, 169, 58, 183),
        ),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: AuthGate(),
    );
  }
}
