import 'package:flutter/material.dart';
import 'screens/login.dart';
import 'services/local_db.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Seed demo account (no-op if already exists)
  await LocalDB.seedDemoUser();

  // Seed starter tasks for ALL existing users who have none yet
  await LocalDB.seedTasksForAllUsers();

  // Backfill paternalDays / maternalDays for users created before these fields existed
  await LocalDB.migrateLeaveBalances();

  // Backfill leaderId / members / task.assignedTo for projects created before leader feature
  await LocalDB.migrateProjectLeaderFields();

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
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
      },
    );
  }
}