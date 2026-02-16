import 'package:flutter/material.dart';
import '../widgets/feature_tour_overlay.dart';

class TourStepsData {
  static List<TourStep> getHomeTourSteps() {
    return [
      // Step 1: Welcome
      TourStep(
        title: 'Welcome! 👋',
        description:
            'Let\'s take a quick tour to help you get started. You can skip anytime or click Next to continue.',
        icon: Icons.waving_hand,
        color: Colors.blue,
        pageIndex: 2,
      ),
      
      // Step 2: Explain current page
      TourStep(
        title: 'Budget Goals 📊',
        description:
            'This page shows your financial overview. Follow the 50-30-20 rule: 50% essentials, 30% wants, 20% savings.',
        icon: Icons.pie_chart,
        color: Colors.purple,
        pageIndex: 2,
      ),
      
      // Step 3: Track progress
      TourStep(
        title: 'Track Your Progress 📈',
        description:
            'Green bars = on track, Red bars = need adjustment. Compare your actual spending with recommendations.',
        icon: Icons.insights,
        color: Colors.green,
        pageIndex: 2,
      ),
      
      // Step 4: Switch to Transactions
      TourStep(
        title: 'View Transactions 📱',
        description:
            'All your expenses are tracked automatically from SMS. Let\'s check them out!',
        icon: Icons.receipt_long,
        color: Colors.blue,
        pageIndex: 0,
      ),
      
      // Step 5: Transactions page
      TourStep(
        title: 'Transaction List 💳',
        description:
            'Every expense shows merchant, amount, and category. Tap any transaction to recategorize it.',
        icon: Icons.list_alt,
        color: Colors.teal,
        pageIndex: 0,
      ),
      
      // Step 6: Budget page
      TourStep(
        title: 'Budget Overview 💰',
        description:
            'See your total income, expenses, and remaining balance. The pie chart shows spending distribution.',
        icon: Icons.account_balance_wallet,
        color: Colors.orange,
        pageIndex: 1,
      ),
      
      // Step 7: Budget breakdown
      TourStep(
        title: 'Category Breakdown 🎯',
        description:
            'Track spending across all categories like groceries, transport, entertainment, and more.',
        icon: Icons.pie_chart_outline,
        color: Colors.green,
        pageIndex: 1,
      ),
      
      // Step 8: Back to 50-30-20
      TourStep(
        title: 'Essential vs Wants 🏠',
        description:
            'The orange card tracks needs (rent, food, bills). The purple card tracks wants (shopping, entertainment).',
        icon: Icons.compare_arrows,
        color: Colors.purple,
        pageIndex: 2,
      ),
      
      // Step 9: Set caps
      TourStep(
        title: 'Set Spending Limits 🔔',
        description:
            'Tap any category card, then the three dots (⋮) to set custom spending caps. Get alerts when you\'re close!',
        icon: Icons.notifications_active,
        color: Colors.red,
        pageIndex: 2,
      ),
      
      // Step 10: Navigation tip
      TourStep(
        title: 'Quick Navigation 🎯',
        description:
            'Use the menu (≡) at top-left anytime to switch between Transactions, Budget, and 50-30-20 pages.',
        icon: Icons.menu,
        color: Colors.blue,
        pageIndex: 2,
      ),
      
      // Step 11: Help
      TourStep(
        title: 'Need Help? 🆘',
        description:
            'Tap the (?) icon at top-right or go to Menu → Restart App Tour to see this guide again.',
        icon: Icons.help_outline,
        color: Colors.orange,
        pageIndex: 2,
      ),
      
      // Step 12: Done
      TourStep(
        title: 'All Set! 🎉',
        description:
            'You\'re ready to track expenses and manage your budget. Start your financial journey now!',
        icon: Icons.celebration,
        color: Colors.amber,
        pageIndex: 2,
      ),
    ];
  }
}