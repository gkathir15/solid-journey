import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'src/view/home_screen.dart';
import 'src/view_model/home_view_model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'On-Device AI Filter',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: ChangeNotifierProvider(
        create: (_) => HomeViewModel(),
        child: const HomeScreen(),
      ),
    );
  }
}
