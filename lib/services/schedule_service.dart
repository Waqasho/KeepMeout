import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomTimeOfDay {
  final int hour;
  final int minute;

  const CustomTimeOfDay({required this.hour, required this.minute});

  String get formatted {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  int get totalMinutes => hour * 60 + minute;

  bool isAfter(CustomTimeOfDay other) {
    return totalMinutes > other.totalMinutes;
  }

  bool isBefore(CustomTimeOfDay other) {
    return totalMinutes < other.totalMinutes;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomTimeOfDay && other.hour == hour && other.minute == minute;
  }

  @override
  int get hashCode => hour.hashCode ^ minute.hashCode;
}

class Schedule {
  final String id;
  final String name;
  final CustomTimeOfDay startTime;
  final CustomTimeOfDay endTime;
  final List<int> weekdays; // 1-7 (Monday-Sunday)
  final bool isEnabled;

  Schedule({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.weekdays,
    this.isEnabled = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'startTime': {
        'hour': startTime.hour,
        'minute': startTime.minute,
      },
      'endTime': {
        'hour': endTime.hour,
        'minute': endTime.minute,
      },
      'weekdays': weekdays,
      'isEnabled': isEnabled,
    };
  }

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'],
      name: json['name'],
      startTime: CustomTimeOfDay(
        hour: json['startTime']['hour'],
        minute: json['startTime']['minute'],
      ),
      endTime: CustomTimeOfDay(
        hour: json['endTime']['hour'],
        minute: json['endTime']['minute'],
      ),
      weekdays: List<int>.from(json['weekdays']),
      isEnabled: json['isEnabled'] ?? true,
    );
  }

  Schedule copyWith({
    String? id,
    String? name,
    CustomTimeOfDay? startTime,
    CustomTimeOfDay? endTime,
    List<int>? weekdays,
    bool? isEnabled,
  }) {
    return Schedule(
      id: id ?? this.id,
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      weekdays: weekdays ?? this.weekdays,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}

class ScheduleService extends ChangeNotifier {
  List<Schedule> _schedules = [];
  Timer? _checkTimer;
  Schedule? _activeSchedule;
  
  // Callback functions
  VoidCallback? _onLockScreen;
  VoidCallback? _onUnlockScreen;

  List<Schedule> get schedules => List.unmodifiable(_schedules);
  Schedule? get activeSchedule => _activeSchedule;
  bool get hasActiveSchedule => _activeSchedule != null;

  ScheduleService() {
    _loadSchedules();
    _startScheduleChecker();
  }

  // Set callback functions
  void setCallbacks({
    VoidCallback? onLockScreen,
    VoidCallback? onUnlockScreen,
  }) {
    _onLockScreen = onLockScreen;
    _onUnlockScreen = onUnlockScreen;
  }

  // Load schedules from shared preferences
  Future<void> _loadSchedules() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final schedulesJson = prefs.getStringList('schedules') ?? [];
      
      _schedules = schedulesJson
          .map((json) => Schedule.fromJson(jsonDecode(json)))
          .toList();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading schedules: $e');
    }
  }

  // Save schedules to shared preferences
  Future<void> _saveSchedules() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final schedulesJson = _schedules
          .map((schedule) => jsonEncode(schedule.toJson()))
          .toList();
      
      await prefs.setStringList('schedules', schedulesJson);
    } catch (e) {
      debugPrint('Error saving schedules: $e');
    }
  }

  // Add a new schedule
  Future<void> addSchedule(Schedule schedule) async {
    _schedules.add(schedule);
    await _saveSchedules();
    notifyListeners();
  }

  // Update an existing schedule
  Future<void> updateSchedule(String id, Schedule updatedSchedule) async {
    final index = _schedules.indexWhere((s) => s.id == id);
    if (index != -1) {
      _schedules[index] = updatedSchedule;
      await _saveSchedules();
      notifyListeners();
    }
  }

  // Delete a schedule
  Future<void> deleteSchedule(String id) async {
    _schedules.removeWhere((s) => s.id == id);
    if (_activeSchedule?.id == id) {
      _activeSchedule = null;
    }
    await _saveSchedules();
    notifyListeners();
  }

  // Toggle schedule enabled/disabled
  Future<void> toggleSchedule(String id) async {
    final index = _schedules.indexWhere((s) => s.id == id);
    if (index != -1) {
      _schedules[index] = _schedules[index].copyWith(
        isEnabled: !_schedules[index].isEnabled,
      );
      await _saveSchedules();
      notifyListeners();
    }
  }

  // Start the schedule checker timer
  void _startScheduleChecker() {
    _checkTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkSchedules();
    });
  }

  // Check if any schedule should be active
  void _checkSchedules() {
    final now = DateTime.now();
    final currentTime = CustomTimeOfDay(hour: now.hour, minute: now.minute);
    final currentWeekday = now.weekday; // 1-7 (Monday-Sunday)

    Schedule? shouldBeActive;

    for (final schedule in _schedules) {
      if (!schedule.isEnabled) continue;
      if (!schedule.weekdays.contains(currentWeekday)) continue;

      // Check if current time is within schedule range
      if (schedule.startTime.isBefore(schedule.endTime)) {
        // Same day schedule (e.g., 09:00 - 17:00)
        if (currentTime.totalMinutes >= schedule.startTime.totalMinutes &&
            currentTime.totalMinutes < schedule.endTime.totalMinutes) {
          shouldBeActive = schedule;
          break;
        }
      } else {
        // Overnight schedule (e.g., 22:00 - 06:00)
        if (currentTime.totalMinutes >= schedule.startTime.totalMinutes ||
            currentTime.totalMinutes < schedule.endTime.totalMinutes) {
          shouldBeActive = schedule;
          break;
        }
      }
    }

    // Handle schedule changes
    if (shouldBeActive != _activeSchedule) {
      if (shouldBeActive != null && _activeSchedule == null) {
        // Schedule started
        _activeSchedule = shouldBeActive;
        _onLockScreen?.call();
        notifyListeners();
      } else if (shouldBeActive == null && _activeSchedule != null) {
        // Schedule ended
        _activeSchedule = null;
        _onUnlockScreen?.call();
        notifyListeners();
      } else if (shouldBeActive != null && _activeSchedule != null) {
        // Different schedule became active
        _activeSchedule = shouldBeActive;
        notifyListeners();
      }
    }
  }

  // Get next scheduled event
  String getNextScheduleInfo() {
    if (_schedules.isEmpty) return 'No schedules configured';
    return 'Next schedule check in progress...';
  }

  // Get weekday names
  static List<String> get weekdayNames => [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 
    'Friday', 'Saturday', 'Sunday'
  ];

  // Get weekday short names
  static List<String> get weekdayShortNames => [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }
}

