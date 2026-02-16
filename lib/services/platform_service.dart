import 'package:flutter/services.dart';
import 'dart:convert';
import '../utils/constants.dart';

class PlatformService {
  static const platform = MethodChannel(AppConstants.methodChannel);
  static const EventChannel transactionChannel = EventChannel(AppConstants.eventChannel);

  static Future<bool> isNotificationServiceEnabled() async {
    try {
      return await platform.invokeMethod('isNotificationServiceEnabled');
    } on PlatformException catch (e) {
      print('Error checking notification service: ${e.message}');
      return false;
    }
  }

  static Future<void> openNotificationSettings() async {
    try {
      await platform.invokeMethod('openNotificationSettings');
    } on PlatformException catch (e) {
      print('Error opening notification settings: ${e.message}');
    }
  }

  static Future<bool> checkOverlayPermission() async {
    try {
      return await platform.invokeMethod('checkOverlayPermission');
    } on PlatformException catch (e) {
      print('Error checking overlay permission: ${e.message}');
      return false;
    }
  }

  static Future<void> requestOverlayPermission() async {
    try {
      await platform.invokeMethod('requestOverlayPermission');
    } on PlatformException catch (e) {
      print('Error requesting overlay permission: ${e.message}');
    }
  }

  static Future<String> getSavedTransactions() async {
    try {
      return await platform.invokeMethod('getSavedTransactions');
    } catch (e) {
      print('Error getting saved transactions: $e');
      return '[]';
    }
  }

  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      await platform.invokeMethod('saveUserData', json.encode(userData));
    } catch (e) {
      print('Error saving user data: $e');
    }
  }

  static Future<Map<String, dynamic>> getUserData() async {
    try {
      final String result = await platform.invokeMethod('getUserData');
      return json.decode(result);
    } catch (e) {
      print('Error getting user data: $e');
      return {};
    }
  }

  static Future<bool> isOnboardingCompleted() async {
    try {
      return await platform.invokeMethod('isOnboardingCompleted');
    } catch (e) {
      print('Error checking onboarding: $e');
      return false;
    }
  }

  static Future<void> saveCategoryCaps(Map<String, dynamic> categoryCaps) async {
    try {
      await platform.invokeMethod('saveCategoryCaps', {
        'categoryCaps': json.encode(categoryCaps),
      });
      
      final userData = await getUserData();
      userData['category_caps'] = categoryCaps;
      await saveUserData(userData);
      
      print('✅ Category caps saved: $categoryCaps');
    } catch (e) {
      print('❌ Error saving category caps: $e');
    }
  }

  static Future<void> sendCapWarningNotification({
    required String category,
    required double currentSpending,
    required double capAmount,
    required double percentage,
    required String type,
  }) async {
    try {
      await platform.invokeMethod('showCapWarningNotification', {
        'category': category,
        'currentSpending': currentSpending,
        'capAmount': capAmount,
        'percentage': percentage,
        'type': type,
      });
    } catch (e) {
      print('Error sending cap warning: $e');
    }
  }

  static void setupMethodCallHandler(Function(String category) onOpenCategory) {
    platform.setMethodCallHandler((call) async {
      if (call.method == 'openCategory') {
        final category = call.arguments['category'] as String?;
        if (category != null) {
          await Future.delayed(Duration(milliseconds: 300));
          onOpenCategory(category);
        }
      }
    });
  }
}