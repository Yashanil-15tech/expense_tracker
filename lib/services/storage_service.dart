import 'dart:convert';
import '../models/transaction.dart';
import 'platform_service.dart';

class StorageService {
  static Future<List<Transaction>> loadTransactions() async {
    try {
      final String result = await PlatformService.getSavedTransactions();
      final List<dynamic> savedTransactions = json.decode(result);

      return savedTransactions
          .map((data) => Transaction.fromJson(data))
          .toList();
    } catch (e) {
      print('Error loading transactions: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> loadUserData() async {
    try {
      return await PlatformService.getUserData();
    } catch (e) {
      print('Error loading user data: $e');
      return {};
    }
  }

  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      await PlatformService.saveUserData(userData);
    } catch (e) {
      print('Error saving user data: $e');
    }
  }
}