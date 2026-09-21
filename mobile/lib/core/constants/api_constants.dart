import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConstants {
  // Automatically selects host according to execution target
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8001/api/';
    } else if (Platform.isAndroid) {
      // 10.0.2.2 points to host machine from Android emulator
      return 'http://10.0.2.2:8001/api/';
    } else {
      // iOS Simulator or desktop
      return 'http://127.0.0.1:8001/api/';
    }
  }

  // Auth endpoints
  static const String login = 'auth/login/';
  static const String register = 'auth/register/';
  static const String tokenRefresh = 'auth/token/refresh/';
  static const String profile = 'auth/profile/';

  // Mess endpoints
  static const String messes = 'messes/';
  static const String joinMess = 'messes/join/';

  // Meals & Finance endpoints
  static String cycles(int messId) => 'messes/$messId/cycles/';
  static String activeCycle(int messId) => 'messes/$messId/cycles/active/';
  static String meals(int messId) => 'messes/$messId/meals/';
  static String bulkMeals(int messId) => 'messes/$messId/meals/bulk/';
  static String deposits(int messId) => 'messes/$messId/deposits/';
  static String expenses(int messId) => 'messes/$messId/expenses/';
  static String balanceSheet(int messId, int cycleId) =>
      'messes/$messId/cycles/$cycleId/balance-sheet/';
}