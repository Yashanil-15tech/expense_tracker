import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'single_category_detail_page.dart';
import '../screens/set_catgeory_cap_screen.dart';

class CategoryGroupDetailPage extends StatefulWidget {
  final String title;
  final List<String> categories;
  final List<Transaction> transactions;
  final double totalAmount;
  final double recommendedBudget;
  final Color color;
  final Map<String, dynamic> categoryCaps;
  final double monthlyIncome;
  final Function(Map<String, dynamic>) onSaveCaps;
  final Map<String, double> essentialExpenses;
  final List<String> essentialCategories;
  final List<String> nonEssentialCategories;
  final double recommendedNonEssentialBudget;

  const CategoryGroupDetailPage({
    Key? key,
    required this.title,
    required this.categories,
    required this.transactions,
    required this.totalAmount,
    required this.recommendedBudget,
    required this.color,
    required this.categoryCaps,
    required this.monthlyIncome,
    required this.onSaveCaps,
    required this.essentialExpenses,
    required this.essentialCategories,
    required this.nonEssentialCategories,
    required this.recommendedNonEssentialBudget,
  }) : super(key: key);

  @override
  State<CategoryGroupDetailPage> createState() => _CategoryGroupDetailPageState();
}

class _CategoryGroupDetailPageState extends State<CategoryGroupDetailPage> {
  void _showSetCapsDialog(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SetCategoryCapScreen(
          categories: widget.categories,
          currentCaps: widget.categoryCaps,
          color: widget.color,
          monthlyIncome: widget.monthlyIncome,
          onSave: widget.onSaveCaps,
          essentialExpenses: widget.essentialExpenses,
          essentialCategories: widget.essentialCategories,
          nonEssentialCategories: widget.nonEssentialCategories,
          recommendedNonEssentialBudget: widget.recommendedNonEssentialBudget,
        ),
      ),
    );

    if (result == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    Map<String, List<Transaction>> transactionsByCategory = {};
    Map<String, double> categoryTotals = {};

    for (var transaction in widget.transactions) {
      if (transaction.type == 'DEBIT' && widget.categories.contains(transaction.category)) {
        if (!transactionsByCategory.containsKey(transaction.category)) {
          transactionsByCategory[transaction.category] = [];
          categoryTotals[transaction.category] = 0;
        }
        transactionsByCategory[transaction.category]!.add(transaction);
        categoryTotals[transaction.category] = (categoryTotals[transaction.category] ?? 0) + transaction.amount;
      }
    }

    final sortedCategories = categoryTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: widget.color,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            tooltip: 'More options',
            onSelected: (value) {
              if (value == 'set_caps') {
                _showSetCapsDialog(context);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'set_caps',
                child: Row(
                  children: [
                    Icon(Icons.notifications_active, size: 20, color: Colors.grey[700]),
                    const SizedBox(width: 8),
                    const Text('Set Spending Caps'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(color: widget.color.withOpacity(0.3), width: 2),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Total Spending',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  Helpers.formatCurrency(widget.totalAmount, showDecimals: false),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: widget.color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Budget: ${Helpers.formatCurrency(widget.recommendedBudget, showDecimals: false)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: widget.recommendedBudget > 0 ? (widget.totalAmount / widget.recommendedBudget).clamp(0.0, 1.0) : 0.0,
                    backgroundColor: Colors.grey[200],
                    color: widget.totalAmount > widget.recommendedBudget ? Colors.red : widget.color,
                    minHeight: 12,
                  ),
                ),
                if (_hasCapWarnings(categoryTotals)) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${_getCapWarningCount(categoryTotals)} ${_getCapWarningCount(categoryTotals) == 1 ? 'category has' : 'categories have'} spending warnings',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.orange.shade900,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: sortedCategories.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No transactions yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: sortedCategories.length,
                    itemBuilder: (context, index) {
                      final categoryName = sortedCategories[index].key;
                      final categoryTotal = sortedCategories[index].value;
                      final categoryTransactions = transactionsByCategory[categoryName]!;
                      final percentage = widget.totalAmount > 0 ? (categoryTotal / widget.totalAmount * 100) : 0.0;

                      final capInfo = _getCategoryCapInfo(categoryName, categoryTotal);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SingleCategoryDetailPage(
                                  categoryName: categoryName,
                                  transactions: categoryTransactions,
                                  totalAmount: categoryTotal,
                                  color: AppConstants.getCategoryColor(categoryName),
                                  icon: AppConstants.getCategoryIcon(categoryName),
                                  capInfo: capInfo,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppConstants.getCategoryColor(categoryName).withOpacity(0.2),
                                  child: Icon(
                                    AppConstants.getCategoryIcon(categoryName),
                                    color: AppConstants.getCategoryColor(categoryName),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              categoryName,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          if (capInfo['hasCap'] as bool) ...[
                                            Icon(
                                              Icons.notifications_active,
                                              size: 16,
                                              color: capInfo['capColor'] as Color,
                                            ),
                                            const SizedBox(width: 4),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${categoryTransactions.length} transaction${categoryTransactions.length != 1 ? 's' : ''} • ${percentage.toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      if (capInfo['hasCap'] as bool) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          capInfo['message'] as String,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: capInfo['capColor'] as Color,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: (capInfo['hasCap'] as bool)
                                              ? (categoryTotal / (capInfo['capAmount'] as double)).clamp(0.0, 1.0)
                                              : percentage / 100,
                                          backgroundColor: Colors.grey[200],
                                          color: (capInfo['hasCap'] as bool)
                                              ? capInfo['capColor'] as Color
                                              : AppConstants.getCategoryColor(categoryName),
                                          minHeight: 6,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      Helpers.formatCurrency(categoryTotal, showDecimals: false),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppConstants.getCategoryColor(categoryName),
                                      ),
                                    ),
                                    if (capInfo['hasCap'] as bool) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        '/ ${Helpers.formatCurrency(capInfo['capAmount'] as double, showDecimals: false)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 4),
                                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getCategoryCapInfo(String category, double currentSpending) {
    if (!widget.categoryCaps.containsKey(category)) {
      return {
        'hasCap': false,
        'capAmount': 0.0,
        'percentage': 0.0,
        'message': '',
        'capColor': Colors.grey,
      };
    }

    final capConfig = widget.categoryCaps[category] as Map<String, dynamic>;
    final capType = capConfig['type'] as String;
    final capValue = (capConfig['value'] as num).toDouble();

    double capAmount;
    if (capType == 'percentage') {
      final onboardingLimit = Helpers.getOnboardingLimit(
        category,
        widget.essentialExpenses,
        widget.nonEssentialCategories,
        widget.recommendedNonEssentialBudget,
      );
      if (onboardingLimit != null) {
        capAmount = onboardingLimit * capValue / 100;
      } else {
        capAmount = widget.monthlyIncome * capValue / 100;
      }
    } else {
      capAmount = capValue;
    }

    final percentage = (currentSpending / capAmount * 100);
    Color capColor;
    String message;

    if (percentage >= 100) {
      capColor = Colors.red;
      message = 'Cap exceeded by ${(percentage - 100).toStringAsFixed(0)}%';
    } else if (percentage >= 80) {
      capColor = Colors.orange;
      message = '${percentage.toStringAsFixed(0)}% of cap used';
    } else {
      capColor = Colors.green;
      message = '${percentage.toStringAsFixed(0)}% of cap used';
    }

    return {
      'hasCap': true,
      'capAmount': capAmount,
      'percentage': percentage,
      'message': message,
      'capColor': capColor,
    };
  }

  bool _hasCapWarnings(Map<String, double> categoryTotals) {
    for (var entry in categoryTotals.entries) {
      final capInfo = _getCategoryCapInfo(entry.key, entry.value);
      if ((capInfo['hasCap'] as bool) && (capInfo['percentage'] as double) >= 80) {
        return true;
      }
    }
    return false;
  }

  int _getCapWarningCount(Map<String, double> categoryTotals) {
    int count = 0;
    for (var entry in categoryTotals.entries) {
      final capInfo = _getCategoryCapInfo(entry.key, entry.value);
      if ((capInfo['hasCap'] as bool) && (capInfo['percentage'] as double) >= 80) {
        count++;
      }
    }
    return count;
  }
}