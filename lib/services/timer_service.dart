import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:waqas_lock/services/device_admin_service.dart';

class TimerService extends ChangeNotifier {
  Timer? _timer;
  int _remainingSeconds = 0;
  int _totalSeconds = 0;
  bool _isRunning = false;
  
  // Callback function to be called when timer completes
  VoidCallback? _onTimerComplete;
  
  bool get isRunning => _isRunning;
  int get remainingSeconds => _remainingSeconds;
  int get totalSeconds => _totalSeconds;
  
  double get progress {
    if (_totalSeconds == 0) return 0.0;
    return (_totalSeconds - _remainingSeconds) / _totalSeconds;
  }
  
  String get formattedTime {
    final hours = _remainingSeconds ~/ 3600;
    final minutes = (_remainingSeconds % 3600) ~/ 60;
    final seconds = _remainingSeconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }
  
  // Start timer with specified duration in minutes
  void startTimer(int minutes, {VoidCallback? onComplete}) {
    stopTimer(); // Stop any existing timer
    
    _totalSeconds = minutes * 60;
    _remainingSeconds = _totalSeconds;
    _isRunning = true;
    _onTimerComplete = onComplete;
    
    // Lock screen immediately when timer starts
    _lockScreenAutomatically();
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _completeTimer();
      }
    });
    
    notifyListeners();
  }

  // Automatically lock screen using Device Admin
  Future<void> _lockScreenAutomatically() async {
    try {
      final bool isAdminActive = await DeviceAdminService.isDeviceAdminActive();
      if (isAdminActive) {
        final bool success = await DeviceAdminService.lockScreen();
        if (success) {
          print('Screen locked automatically');
        } else {
          print('Failed to lock screen automatically');
        }
      } else {
        print('Device Admin not active - cannot lock screen automatically');
      }
    } catch (e) {
      print('Error locking screen automatically: $e');
    }
  }
  
  // Stop the timer
  void stopTimer() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _remainingSeconds = 0;
    _totalSeconds = 0;
    _onTimerComplete = null;
    notifyListeners();
  }
  
  // Add time to current timer
  void addTime(int minutes) {
    if (_isRunning) {
      _remainingSeconds += minutes * 60;
      _totalSeconds += minutes * 60;
      notifyListeners();
    }
  }
  
  // Complete timer and trigger callback
  void _completeTimer() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _remainingSeconds = 0;
    
    // Call the completion callback if set
    if (_onTimerComplete != null) {
      _onTimerComplete!();
    }
    
    notifyListeners();
  }
  
  // Check if timer is about to expire (less than 1 minute)
  bool get isAboutToExpire => _isRunning && _remainingSeconds <= 60;
  
  // Get percentage of time elapsed
  int get percentageElapsed {
    if (_totalSeconds == 0) return 0;
    return (((_totalSeconds - _remainingSeconds) / _totalSeconds) * 100).round();
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

