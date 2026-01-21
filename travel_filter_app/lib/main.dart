import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:travel_filter_app/gemma_llm_service.dart';
import 'package:travel_filter_app/home_screen.dart';

void main() {
  // Initialize logger
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GemmaLLMService _gemmaService;

  @override
  void initState() {
    super.initState();
    _gemmaService = GemmaLLMService();
  }

  @override
  void dispose() {
    _gemmaService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Travel Filter App - Gemma LLM',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: HomeScreen(gemmaService: _gemmaService),
    );
  }
}
