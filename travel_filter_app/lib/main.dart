import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'phase5_home.dart';

void main() {
  // Initialize logger with detailed formatting
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    final time = record.time.toString().split('.')[0];
    debugPrint('[${record.level.name}] $time: ${record.loggerName}: ${record.message}');
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Travel Planner - AI-First GenUI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      home: const Phase5Home(),
    );
  }
}
