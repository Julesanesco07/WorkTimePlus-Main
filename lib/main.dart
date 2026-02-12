import 'package:flutter/material.dart';
import 'login.dart';

void main() {
  runApp(const WorktimePlusApp());
}

class WorktimePlusApp extends StatelessWidget {
  const WorktimePlusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WorkTime+',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2B457B)),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}