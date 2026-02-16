import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../utils/helpers.dart';
import '../screens/category_group_detail_page.dart';

class ExpectationsView extends StatelessWidget {
  final double monthlyIncome;
  final double averagePastExpenditure;
  final double savingsAmount;
  final String savingsType;
  final double totalEssentialCategoryExpenses;
  final double totalNonEssentialCategoryExpenses;
  final double totalOnboardingEssentialBudget;
  final double recommendedNonEssentialBudget;
  final double recommendedSavings;
  final List<String> dynamicEssentialCategories;
  final List<String> dynamicNonEssentialCategories;
  final List<Transaction> transactions;
  final Map<String, dynamic> categoryCaps;
  final Map<String, double> essentialExpenses;
  final Function(Map<String, dynamic>) onSaveCaps;

  const ExpectationsView({
    Key? key,
    required this.monthlyIncome,
    required this.averagePastExpenditure,
    required this.savingsAmount,
    required this.savingsType,
    required this.totalEssentialCategoryExpenses,
    required this.totalNonEssentialCategoryExpenses,
    required this.totalOnboardingEssentialBudget,
    required this.recommendedNonEssentialBudget,
    required this.recommendedSavings,
    required this.dynamicEssentialCategories,
    required this.dynamicNonEssentialCategories,
    required this.transactions,
    required this.categoryCaps,
    required this.essentialExpenses,
    required this.onSaveCaps,
  }) : super(key: key);

  double get essentialSpendingPercentage {
    return totalOnboardingEssentialBudget > 0
        ? (totalEssentialCategoryExpenses / totalOnboardingEssentialBudget * 100)
        : 0.0;
  }

  double get nonEssentialSpendingPercentage {
    return recommendedNonEssentialBudget > 0
        ? (totalNonEssentialCategoryExpenses / recommendedNonEssentialBudget * 100)
        : 0.0;
  }

  double get savingsSpendingPercentage {
    final savingsGoal = savingsType == 'percentage'
        ? (monthlyIncome * savingsAmount / 100)
        : savingsAmount;
    return recommendedSavings > 0 ? (savingsGoal / recommendedSavings * 100) : 0.0;
  }

  double get essentialOverspendActual {
    return totalEssentialCategoryExpenses - totalOnboardingEssentialBudget;
  }

  double get nonEssentialOverspend {
    return totalNonEssentialCategoryExpenses - recommendedNonEssentialBudget;
  }

  double get savingsOverspend {
    final savingsGoal = savingsType == 'percentage'
        ? (monthlyIncome * savingsAmount / 100)
        : savingsAmount;
    return savingsGoal - recommendedSavings;
  }

  @override
  Widget build(BuildContext context) {
    final savingsGoal = savingsType == 'percentage'
        ? (monthlyIncome * savingsAmount / 100)
        : savingsAmount;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildHeaderCard(),
        SizedBox(height: 16),
        _buildRecommendedBudgetCard(context, savingsGoal),
        SizedBox(height: 16),
        if (essentialOverspendActual > 10 || nonEssentialOverspend > 10)
          _buildAlertCard()
        else
          _buildSuccessCard(),
      ],
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 4,
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(Icons.pie_chart_outline, size: 48, color: Colors.blue),
            SizedBox(height: 12),
            Text(
              '50-30-20 Budget Rule',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Based on your average monthly spending of ${Helpers.formatCurrency(averagePastExpenditure, showDecimals: false)}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedBudgetCard(BuildContext context, double savingsGoal) {
    return Card(
      elevation: 4,
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.green, size: 28),
                SizedBox(width: 12),
                Text(
                  'Recommended Budget',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'How you should allocate your ${Helpers.formatCurrency(averagePastExpenditure, showDecimals: false)}',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            SizedBox(height: 20),
            _buildEssentialCard(context),
            SizedBox(height: 12),
            _buildNonEssentialCard(context),
            SizedBox(height: 12),
            _buildSavingsCard(savingsGoal),
          ],
        ),
      ),
    );
  }

  Widget _buildEssentialCard(BuildContext context) {
    return GestureDetector(
      onTap: () => _openCategoryGroupPage(context, true),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200, width: 2),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.shopping_cart, color: Colors.orange, size: 24),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Essential', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('Your budget', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      Helpers.formatCurrency(totalOnboardingEssentialBudget, showDecimals: false),
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Text('Your spending: ${Helpers.formatCurrency(totalEssentialCategoryExpenses, showDecimals: false)}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                SizedBox(width: 8),
                Text('(${essentialSpendingPercentage.toStringAsFixed(1)}%)',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              ],
            ),
            if (essentialOverspendActual.abs() > 10)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(
                      essentialOverspendActual > 0 ? Icons.warning_amber : Icons.check_circle,
                      color: essentialOverspendActual > 0 ? Colors.red : Colors.green,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      essentialOverspendActual > 0
                          ? 'Over by ${Helpers.formatCurrency(essentialOverspendActual, showDecimals: false)}'
                          : 'Under by ${Helpers.formatCurrency(essentialOverspendActual.abs(), showDecimals: false)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: essentialOverspendActual > 0 ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNonEssentialCard(BuildContext context) {
    return GestureDetector(
      onTap: () => _openCategoryGroupPage(context, false),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.purple.shade200, width: 2),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.movie, color: Colors.purple, size: 24),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Non-Essential', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('30% of income', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      Helpers.formatCurrency(recommendedNonEssentialBudget, showDecimals: false),
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.purple),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Text('Your spending: ${Helpers.formatCurrency(totalNonEssentialCategoryExpenses, showDecimals: false)}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                SizedBox(width: 8),
                Text('(${nonEssentialSpendingPercentage.toStringAsFixed(1)}%)',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              ],
            ),
            if (nonEssentialOverspend.abs() > 10)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(
                      nonEssentialOverspend > 0 ? Icons.warning_amber : Icons.check_circle,
                      color: nonEssentialOverspend > 0 ? Colors.red : Colors.green,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      nonEssentialOverspend > 0
                          ? 'Over by ${Helpers.formatCurrency(nonEssentialOverspend, showDecimals: false)}'
                          : 'Under by ${Helpers.formatCurrency(nonEssentialOverspend.abs(), showDecimals: false)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: nonEssentialOverspend > 0 ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavingsCard(double savingsGoal) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200, width: 2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.savings, color: Colors.green, size: 24),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Savings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('20% of income', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ],
              ),
              Text(
                Helpers.formatCurrency(recommendedSavings, showDecimals: false),
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Text('Your goal: ${Helpers.formatCurrency(savingsGoal, showDecimals: false)}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700])),
              SizedBox(width: 8),
              Text('(${savingsSpendingPercentage.toStringAsFixed(1)}%)',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            ],
          ),
          if (savingsOverspend.abs() > 10)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(
                    savingsOverspend > 0 ? Icons.trending_up : Icons.check_circle,
                    color: savingsOverspend > 0 ? Colors.blue : Colors.green,
                    size: 16,
                  ),
                  SizedBox(width: 4),
                  Text(
                    savingsOverspend > 0
                        ? '${(savingsOverspend / recommendedSavings * 100).toStringAsFixed(0)}% above recommended'
                        : 'Below recommended savings',
                    style: TextStyle(
                      fontSize: 12,
                      color: savingsOverspend > 0 ? Colors.blue : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAlertCard() {
    return Card(
      elevation: 4,
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.red, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Budget Alert',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade900,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'You are overspending in ${essentialOverspendActual > 10 && nonEssentialOverspend > 10 ? 'both Essential and Non-Essential' : essentialOverspendActual > 10 ? 'Essential' : 'Non-Essential'} categories. Try to stay within your budget for better financial health.',
              style: TextStyle(fontSize: 14, color: Colors.red.shade800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessCard() {
    return Card(
      elevation: 4,
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Great job! You are managing your budget well.',
                style: TextStyle(fontSize: 14, color: Colors.green.shade900),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCategoryGroupPage(BuildContext context, bool isEssential) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryGroupDetailPage(
          title: isEssential ? 'Essential Expenses' : 'Non-Essential Expenses',
          categories: isEssential ? dynamicEssentialCategories : dynamicNonEssentialCategories,
          transactions: transactions,
          totalAmount: isEssential ? totalEssentialCategoryExpenses : totalNonEssentialCategoryExpenses,
          recommendedBudget: isEssential ? totalOnboardingEssentialBudget : recommendedNonEssentialBudget,
          color: isEssential ? Colors.orange : Colors.purple,
          categoryCaps: categoryCaps,
          monthlyIncome: monthlyIncome,
          onSaveCaps: onSaveCaps,
          essentialExpenses: essentialExpenses,
          essentialCategories: dynamicEssentialCategories,
          nonEssentialCategories: dynamicNonEssentialCategories,
          recommendedNonEssentialBudget: recommendedNonEssentialBudget,
        ),
      ),
    );
  }
}