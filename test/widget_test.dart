import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:waqas_lock/main.dart';
import 'package:waqas_lock/services/app_state.dart';
import 'package:waqas_lock/services/timer_service.dart';
import 'package:waqas_lock/services/schedule_service.dart';

void main() {
  group('Waqas Lock App Tests', () {
    testWidgets('App should start with home screen', (WidgetTester tester) async {
      await tester.pumpWidget(const WaqasLockApp());
      
      expect(find.text('Waqas Lock'), findsOneWidget);
      expect(find.text('Timer Lock'), findsOneWidget);
      expect(find.text('Schedules'), findsOneWidget);
    });

    testWidgets('Quick timer buttons should be present', (WidgetTester tester) async {
      await tester.pumpWidget(const WaqasLockApp());
      
      expect(find.text('15 min'), findsOneWidget);
      expect(find.text('30 min'), findsOneWidget);
      expect(find.text('1 hour'), findsOneWidget);
      expect(find.text('Custom Timer'), findsOneWidget);
    });

    testWidgets('Lock now button should work', (WidgetTester tester) async {
      await tester.pumpWidget(const WaqasLockApp());
      
      await tester.tap(find.text('Lock Now'));
      await tester.pumpAndSettle();
      
      expect(find.text('Screen is Locked'), findsOneWidget);
    });

    testWidgets('Admin access should require PIN', (WidgetTester tester) async {
      await tester.pumpWidget(const WaqasLockApp());
      
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      
      expect(find.text('Admin Access'), findsOneWidget);
      expect(find.text('Enter Admin PIN'), findsOneWidget);
    });
  });

  group('AppState Tests', () {
    test('Default admin PIN should be 1234', () {
      final appState = AppState();
      expect(appState.verifyAdminPin('1234'), isTrue);
      expect(appState.verifyAdminPin('0000'), isFalse);
    });

    test('Lock and unlock should work', () {
      final appState = AppState();
      
      expect(appState.isLocked, isFalse);
      
      appState.lockScreen();
      expect(appState.isLocked, isTrue);
      
      appState.unlockScreen();
      expect(appState.isLocked, isFalse);
    });

    test('Admin mode should work with correct PIN', () {
      final appState = AppState();
      
      expect(appState.isAdminMode, isFalse);
      
      final result = appState.enterAdminMode('1234');
      expect(result, isTrue);
      expect(appState.isAdminMode, isTrue);
      
      appState.exitAdminMode();
      expect(appState.isAdminMode, isFalse);
    });
  });

  group('TimerService Tests', () {
    test('Timer should start and stop correctly', () {
      final timerService = TimerService();
      
      expect(timerService.isRunning, isFalse);
      expect(timerService.remainingSeconds, equals(0));
      
      timerService.startTimer(1);
      expect(timerService.isRunning, isTrue);
      expect(timerService.remainingSeconds, equals(60));
      
      timerService.stopTimer();
      expect(timerService.isRunning, isFalse);
      expect(timerService.remainingSeconds, equals(0));
    });

    test('Timer formatting should work correctly', () {
      final timerService = TimerService();
      
      timerService.startTimer(65);
      expect(timerService.formattedTime, equals('01:05:00'));
      
      timerService.stopTimer();
      timerService.startTimer(5);
      expect(timerService.formattedTime, equals('05:00'));
    });

    test('Add time should work when timer is running', () {
      final timerService = TimerService();
      
      timerService.startTimer(10);
      final initialTime = timerService.remainingSeconds;
      
      timerService.addTime(5);
      expect(timerService.remainingSeconds, equals(initialTime + 300));
    });
  });

  group('ScheduleService Tests', () {
    test('Schedule should be created correctly', () {
      const schedule = Schedule(
        id: 'test1',
        name: 'Work Hours',
        startTime: CustomTimeOfDay(hour: 9, minute: 0),
        endTime: CustomTimeOfDay(hour: 17, minute: 0),
        weekdays: [1, 2, 3, 4, 5],
        isEnabled: true,
      );
      
      expect(schedule.name, equals('Work Hours'));
      expect(schedule.startTime.hour, equals(9));
      expect(schedule.endTime.hour, equals(17));
      expect(schedule.weekdays.length, equals(5));
      expect(schedule.isEnabled, isTrue);
    });

    test('CustomTimeOfDay formatting should work', () {
      const time1 = CustomTimeOfDay(hour: 9, minute: 0);
      const time2 = CustomTimeOfDay(hour: 17, minute: 30);
      
      expect(time1.formatted, equals('09:00'));
      expect(time2.formatted, equals('17:30'));
    });

    test('CustomTimeOfDay comparison should work', () {
      const time1 = CustomTimeOfDay(hour: 9, minute: 0);
      const time2 = CustomTimeOfDay(hour: 17, minute: 0);
      
      expect(time1.isBefore(time2), isTrue);
      expect(time2.isAfter(time1), isTrue);
      expect(time1.isBefore(time1), isFalse);
    });
  });
}

