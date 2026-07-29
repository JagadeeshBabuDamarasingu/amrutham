import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ui/home_screen.dart';

void main() {
  runApp(const ProviderScope(child: AmruthamApp()));
}

class AmruthamApp extends StatelessWidget {
  const AmruthamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Amrutham',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const HomeScreen(),
    );
  }
}
