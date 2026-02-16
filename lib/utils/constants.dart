import 'package:flutter/material.dart';

class AppConstants {
  static const List<String> categories = [
    'Food',
    'Groceries',
    'Shopping',
    'Clothes',
    'Laundry',
    'Transport',
    'Entertainment',
    'Bills',
    'Health',
    'Others',
  ];

  static const Map<String, String> categoryMapping = {
    'Laundry': 'Laundry',
    'Groceries': 'Groceries',
    'Mess/Food': 'Food',
    'Food': 'Mess/Food',
    'Subscriptions': 'Bills',
    'Bills': 'Subscriptions',
    'Transport': 'Transport',
  };

  static Color getCategoryColor(String category) {
    switch (category) {
      case 'Food':
        return Colors.orange;
      case 'Groceries':
        return Colors.green;
      case 'Shopping':
        return Colors.purple;
      case 'Clothes':
        return Colors.pink;
      case 'Laundry':
        return Colors.blue;
      case 'Transport':
        return Colors.teal;
      case 'Entertainment':
        return Colors.red;
      case 'Bills':
        return Colors.brown;
      case 'Health':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }

  static IconData getCategoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant;
      case 'Groceries':
        return Icons.shopping_cart;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Clothes':
        return Icons.checkroom;
      case 'Laundry':
        return Icons.local_laundry_service;
      case 'Transport':
        return Icons.directions_car;
      case 'Entertainment':
        return Icons.movie;
      case 'Bills':
        return Icons.receipt;
      case 'Health':
        return Icons.local_hospital;
      case 'Uncategorized':
        return Icons.help_outline;
      default:
        return Icons.category;
    }
  }

  static const String methodChannel = 'notification_listener_channel';
  static const String eventChannel = 'transaction_stream';
}