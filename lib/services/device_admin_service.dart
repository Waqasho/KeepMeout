import 'package:flutter/services.dart';

class DeviceAdminService {
  static const MethodChannel _channel = MethodChannel('com.example.waqas_lock/device_admin');

  // Check if device admin is active
  static Future<bool> isDeviceAdminActive() async {
    try {
      final bool isActive = await _channel.invokeMethod('isDeviceAdminActive');
      return isActive;
    } on PlatformException catch (e) {
      print("Failed to check device admin status: '${e.message}'.");
      return false;
    }
  }

  // Request device admin permission
  static Future<void> requestDeviceAdmin() async {
    try {
      await _channel.invokeMethod('requestDeviceAdmin');
    } on PlatformException catch (e) {
      print("Failed to request device admin: '${e.message}'.");
    }
  }

  // Lock the screen immediately
  static Future<bool> lockScreen() async {
    try {
      final bool success = await _channel.invokeMethod('lockScreen');
      return success;
    } on PlatformException catch (e) {
      print("Failed to lock screen: '${e.message}'.");
      return false;
    }
  }
}

