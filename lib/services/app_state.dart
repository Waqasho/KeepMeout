import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState extends ChangeNotifier {
  bool _isLocked = false;
  bool _isAdminMode = false;
  String _adminPin = '1234'; // Default admin PIN
  
  bool get isLocked => _isLocked;
  bool get isAdminMode => _isAdminMode;
  String get adminPin => _adminPin;

  AppState() {
    _loadSettings();
  }

  // Load settings from shared preferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _adminPin = prefs.getString('admin_pin') ?? '1234';
      _isAdminMode = prefs.getBool('is_admin_mode') ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  // Save settings to shared preferences
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('admin_pin', _adminPin);
      await prefs.setBool('is_admin_mode', _isAdminMode);
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }

  // Lock the screen
  void lockScreen() {
    _isLocked = true;
    notifyListeners();
  }

  // Unlock the screen
  void unlockScreen() {
    _isLocked = false;
    notifyListeners();
  }

  // Toggle admin mode
  void toggleAdminMode() {
    _isAdminMode = !_isAdminMode;
    _saveSettings();
    notifyListeners();
  }

  // Verify admin PIN
  bool verifyAdminPin(String pin) {
    return pin == _adminPin;
  }

  // Update admin PIN
  Future<void> updateAdminPin(String newPin) async {
    _adminPin = newPin;
    await _saveSettings();
    notifyListeners();
  }

  // Enter admin mode with PIN verification
  bool enterAdminMode(String pin) {
    if (verifyAdminPin(pin)) {
      _isAdminMode = true;
      _saveSettings();
      notifyListeners();
      return true;
    }
    return false;
  }

  // Exit admin mode
  void exitAdminMode() {
    _isAdminMode = false;
    _saveSettings();
    notifyListeners();
  }
}

