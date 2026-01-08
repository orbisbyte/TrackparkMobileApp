import 'dart:convert';

import 'package:driver_tracking_airport/models/driver_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalSharedPref {
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyDriverModel = 'driver_model';
  static const String _keyAppToken = 'app_token';

  // Get SharedPreferences instance
  static Future<SharedPreferences> get _prefs async =>
      await SharedPreferences.getInstance();

  // ============ Login State ============
  /// Save login state
  static Future<bool> setLoggedIn(bool isLoggedIn) async {
    final prefs = await _prefs;
    return await prefs.setBool(_keyIsLoggedIn, isLoggedIn);
  }

  /// Get login state
  static Future<bool> isLoggedIn() async {
    final prefs = await _prefs;
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  // ============ Driver Model ============
  /// Save driver model
  static Future<bool> saveDriverModel(DriverModel driver) async {
    final prefs = await _prefs;
    final driverJson = jsonEncode(driver.toJson());
    return await prefs.setString(_keyDriverModel, driverJson);
  }

  /// Get driver model
  static Future<DriverModel?> getDriverModel() async {
    final prefs = await _prefs;
    final driverJson = prefs.getString(_keyDriverModel);
    if (driverJson == null) return null;

    try {
      final driverMap = jsonDecode(driverJson) as Map<String, dynamic>;
      return DriverModel.fromJson(driverMap);
    } catch (e) {
      return null;
    }
  }

  /// Clear driver model
  static Future<bool> clearDriverModel() async {
    final prefs = await _prefs;
    return await prefs.remove(_keyDriverModel);
  }

  // ============ App Token ============
  /// Save app token
  static Future<bool> saveAppToken(String token) async {
    final prefs = await _prefs;
    return await prefs.setString(_keyAppToken, token);
  }

  /// Get app token
  static Future<String?> getAppToken() async {
    final prefs = await _prefs;
    return prefs.getString(_keyAppToken);
  }

  /// Clear app token
  static Future<bool> clearAppToken() async {
    final prefs = await _prefs;
    return await prefs.remove(_keyAppToken);
  }

  // ============ Logout ============
  /// Clear all login data
  static Future<bool> logout() async {
    final prefs = await _prefs;
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyDriverModel);
    await prefs.remove(_keyAppToken);
    return true;
  }
}
