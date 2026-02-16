class Helpers {
  static String formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  static String formatCurrency(double amount, {bool showDecimals = true}) {
    if (showDecimals) {
      return '₹${amount.toStringAsFixed(2)}';
    } else {
      return '₹${amount.toStringAsFixed(0)}';
    }
  }

  static double? getOnboardingLimit(
    String category,
    Map<String, double> essentialExpenses,
    List<String> nonEssentialCategories,
    double recommendedNonEssentialBudget,
  ) {
    const Map<String, String> categoryMapping = {
      'Food': 'Mess/Food',
      'Groceries': 'Groceries',
      'Laundry': 'Laundry',
      'Transport': 'Transport',
      'Bills': 'Subscriptions',
    };

    if (essentialExpenses.containsKey(category)) {
      return essentialExpenses[category];
    }

    String? essentialKey = categoryMapping[category];
    if (essentialKey != null && essentialExpenses.containsKey(essentialKey)) {
      return essentialExpenses[essentialKey];
    }

    if (nonEssentialCategories.contains(category)) {
      return recommendedNonEssentialBudget;
    }

    return null;
  }
}