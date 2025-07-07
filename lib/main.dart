import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:waqas_lock/services/app_state.dart';
import 'package:waqas_lock/services/timer_service.dart';
import 'package:waqas_lock/services/schedule_service.dart';
import 'package:waqas_lock/screens/home_screen.dart';
import 'package:waqas_lock/screens/lock_screen.dart';
import 'package:waqas_lock/screens/admin_screen.dart';

void main() {
  runApp(const WaqasLockApp());
}

class WaqasLockApp extends StatelessWidget {
  const WaqasLockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => TimerService()),
        ChangeNotifierProvider(create: (_) => ScheduleService()),
      ],
      child: Consumer<AppState>(
        builder: (context, appState, child) {
          return MaterialApp(
            title: 'Waqas Lock',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.blue,
              fontFamily: 'Roboto',
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            home: appState.isLocked ? const LockScreen() : const HomeScreen(),
            routes: {
              '/home': (context) => const HomeScreen(),
              '/lock': (context) => const LockScreen(),
              '/admin': (context) => const AdminScreen(),
            },
          );
        },
      ),
    );
  }
}

