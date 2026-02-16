import 'package:shared_preferences/shared_preferences.dart';

class TourService {
  static const String _tourCompletedKey = 'app_tour_completed';
  static const String _tourSkippedKey = 'app_tour_skipped';

  static Future<bool> isTourCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_tourCompletedKey) ?? false;
  }

  static Future<void> markTourCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tourCompletedKey, true);
  }

  static Future<void> resetTour() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tourCompletedKey, false);
    await prefs.setBool(_tourSkippedKey, false);
  }
}