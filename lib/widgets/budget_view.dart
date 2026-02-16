import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/helpers.dart';

class BudgetView extends StatelessWidget {
  final double monthlyIncome;
  final double totalExpense;
  final Map<String, double> essentialExpenses;
  final double savings;
  final double essential;
  final double nonEssential;

  const BudgetView({
    Key? key,
    required this.monthlyIncome,
    required this.totalExpense,
    required this.essentialExpenses,
    required this.savings,
    required this.essential,
    required this.nonEssential,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final remaining = monthlyIncome - totalExpense;
    final spentPercentage = monthlyIncome > 0 ? (totalExpense / monthlyIncome * 100) : 0.0;
    final totalForChart = savings + essential + nonEssential;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildPieChart(totalForChart),
        const SizedBox(height: 16),
        _buildMonthlyBudgetCard(remaining, spentPercentage),
        const SizedBox(height: 16),
        _buildBudgetUsageCard(spentPercentage),
        const SizedBox(height: 16),
        if (essentialExpenses.isNotEmpty) _buildEssentialExpensesCard(),
      ],
    );
  }

  Widget _buildPieChart(double totalForChart) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              'Budget Allocation',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: totalForChart > 0
                  ? PieChart(
                      PieChartData(
                        startDegreeOffset: 180,
                        sectionsSpace: 2,
                        centerSpaceRadius: 0,
                        sections: [
                          if (savings > 0)
                            PieChartSectionData(
                              color: Colors.green,
                              value: savings,
                              title: '',
                              radius: 100,
                            ),
                          if (essential > 0)
                            PieChartSectionData(
                              color: Colors.orange,
                              value: essential,
                              title: '',
                              radius: 100,
                            ),
                          if (nonEssential > 0)
                            PieChartSectionData(
                              color: Colors.purple,
                              value: nonEssential,
                              title: '',
                              radius: 100,
                            ),
                        ],
                      ),
                    )
                  : Center(
                      child: Text(
                        'No data available',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildLegendItem('Savings', Colors.green, savings),
                _buildLegendItem('Essential', Colors.orange, essential),
                _buildLegendItem('Non-Essential', Colors.purple, nonEssential),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, double amount) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            Text(
              Helpers.formatCurrency(amount, showDecimals: false),
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMonthlyBudgetCard(double remaining, double spentPercentage) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Budget',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.account_balance_wallet, color: Colors.blue, size: 24),
                    const SizedBox(width: 12),
                    const Text(
                      'Monthly Income',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                Text(
                  Helpers.formatCurrency(monthlyIncome),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.shopping_cart, color: Colors.red, size: 24),
                    const SizedBox(width: 12),
                    const Text(
                      'Total Expenses',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                Text(
                  Helpers.formatCurrency(totalExpense),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.savings,
                      color: remaining > 0 ? Colors.green : Colors.orange,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Remaining',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                Text(
                  Helpers.formatCurrency(remaining),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: remaining > 0 ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetUsageCard(double spentPercentage) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Budget Usage',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${spentPercentage.toStringAsFixed(1)}% spent',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                Text(
                  '${Helpers.formatCurrency(totalExpense, showDecimals: false)}/${Helpers.formatCurrency(monthlyIncome, showDecimals: false)}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: monthlyIncome > 0 ? (totalExpense / monthlyIncome).clamp(0.0, 1.0) : 0.0,
                backgroundColor: Colors.grey[200],
                color: spentPercentage > 90
                    ? Colors.red
                    : spentPercentage > 70
                        ? Colors.orange
                        : Colors.green,
                minHeight: 16,
              ),
            ),
            if (spentPercentage > 90)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You have exceeded 90% of your budget!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
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

  Widget _buildEssentialExpensesCard() {
    final essentialTotal = essentialExpenses.values.fold(0.0, (sum, value) => sum + value);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Essential Expenses',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  Helpers.formatCurrency(essentialTotal),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...essentialExpenses.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key, style: const TextStyle(fontSize: 15)),
                    Text(
                      Helpers.formatCurrency(entry.value),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}