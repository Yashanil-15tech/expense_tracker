import 'package:flutter/material.dart';
import '../utils/helpers.dart';

class GradeView extends StatelessWidget {
  final double monthlyIncome;
  final double totalExpense;
  final double savings;

  const GradeView({
    Key? key,
    required this.monthlyIncome,
    required this.totalExpense,
    required this.savings,
  }) : super(key: key);

  Map<String, dynamic> _calculateGrade() {
    if (monthlyIncome <= 0) {
      return {
        'grade': 'N/A',
        'color': Colors.grey,
        'message': 'Set your monthly income to see your grade',
        'icon': Icons.help_outline,
        'percentage': 0.0,
      };
    }

    final savingsPercentage = (savings / monthlyIncome) * 100;

    if (savingsPercentage <= 0) {
      return {
        'grade': 'F',
        'color': Colors.red.shade900,
        'message': 'No savings this month. Time to cut expenses!',
        'icon': Icons.sentiment_very_dissatisfied,
        'percentage': savingsPercentage,
        'advice': 'You\'re spending more than you earn. Review your expenses and cut unnecessary costs.',
      };
    } else if (savingsPercentage < 10) {
      return {
        'grade': 'E',
        'color': Colors.red.shade700,
        'message': 'Very low savings. You need to improve!',
        'icon': Icons.sentiment_dissatisfied,
        'percentage': savingsPercentage,
        'advice': 'Try to reduce non-essential spending and aim for at least 10% savings.',
      };
    } else if (savingsPercentage < 15) {
      return {
        'grade': 'D',
        'color': Colors.orange.shade700,
        'message': 'Below average savings. Room for improvement.',
        'icon': Icons.sentiment_neutral,
        'percentage': savingsPercentage,
        'advice': 'You\'re on the right track, but try to push towards 15-20% savings.',
      };
    } else if (savingsPercentage < 18) {
      return {
        'grade': 'C',
        'color': Colors.amber.shade700,
        'message': 'Fair savings rate. Keep working on it!',
        'icon': Icons.sentiment_satisfied,
        'percentage': savingsPercentage,
        'advice': 'Good start! Focus on reducing non-essential expenses to reach 20%.',
      };
    } else if (savingsPercentage < 20) {
      return {
        'grade': 'B',
        'color': Colors.lightGreen.shade700,
        'message': 'Good savings! Almost at the recommended level.',
        'icon': Icons.sentiment_satisfied_alt,
        'percentage': savingsPercentage,
        'advice': 'Great job! Just a bit more to reach the 20% recommended savings.',
      };
    } else if (savingsPercentage < 25) {
      return {
        'grade': 'A',
        'color': Colors.green.shade700,
        'message': 'Excellent! You\'re meeting the 50-30-20 rule.',
        'icon': Icons.emoji_events,
        'percentage': savingsPercentage,
        'advice': 'Fantastic! You\'re maintaining a healthy savings rate. Keep it up!',
      };
    } else {
      return {
        'grade': 'A+',
        'color': Colors.green.shade900,
        'message': 'Outstanding! You\'re a savings champion!',
        'icon': Icons.workspace_premium,
        'percentage': savingsPercentage,
        'advice': 'Exceptional performance! Consider investing your extra savings for long-term growth.',
      };
    }
  }

  Color _getProgressColor(double percentage) {
    if (percentage <= 0) return Colors.red.shade900;
    if (percentage < 10) return Colors.red.shade700;
    if (percentage < 15) return Colors.orange.shade700;
    if (percentage < 18) return Colors.amber.shade700;
    if (percentage < 20) return Colors.lightGreen.shade700;
    if (percentage < 25) return Colors.green.shade700;
    return Colors.green.shade900;
  }

  @override
  Widget build(BuildContext context) {
    final gradeData = _calculateGrade();
    final savingsPercentage = gradeData['percentage'] as double;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildGradeCard(gradeData),
        const SizedBox(height: 16),
        _buildSavingsBreakdown(savingsPercentage),
        const SizedBox(height: 16),
        _buildAdviceCard(gradeData),
        const SizedBox(height: 16),
        _buildGradingScaleCard(),
      ],
    );
  }

  Widget _buildGradeCard(Map<String, dynamic> gradeData) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              gradeData['color'].withOpacity(0.1),
              gradeData['color'].withOpacity(0.05),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(
                gradeData['icon'],
                size: 64,
                color: gradeData['color'],
              ),
              const SizedBox(height: 16),
              Text(
                'Your Grade',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  color: gradeData['color'],
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: gradeData['color'].withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Text(
                  gradeData['grade'],
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                gradeData['message'],
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSavingsBreakdown(double savingsPercentage) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.blue, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Savings Breakdown',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildBreakdownRow(
              'Monthly Income',
              Helpers.formatCurrency(monthlyIncome, showDecimals: false),
              Colors.blue,
              Icons.account_balance_wallet,
            ),
            const Divider(height: 32),
            _buildBreakdownRow(
              'Total Expenses',
              Helpers.formatCurrency(totalExpense, showDecimals: false),
              Colors.red,
              Icons.shopping_cart,
            ),
            const Divider(height: 32),
            _buildBreakdownRow(
              'Savings',
              Helpers.formatCurrency(savings, showDecimals: false),
              savings > 0 ? Colors.green : Colors.orange,
              Icons.savings,
            ),
            const SizedBox(height: 24),
            Text(
              'Savings Rate',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${savingsPercentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _getProgressColor(savingsPercentage),
                  ),
                ),
                Text(
                  'Target: 20%',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (savingsPercentage / 25).clamp(0.0, 1.0),
                backgroundColor: Colors.grey[200],
                color: _getProgressColor(savingsPercentage),
                minHeight: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownRow(String label, String value, Color color, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildAdviceCard(Map<String, dynamic> gradeData) {
    if (gradeData['grade'] == 'N/A') return const SizedBox.shrink();

    return Card(
      elevation: 4,
      color: gradeData['color'].withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: gradeData['color'], size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Financial Advice',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              gradeData['advice'] ?? '',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[800],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradingScaleCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.grade, color: Colors.purple, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Grading Scale',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildGradeScaleItem('A+', '> 25%', Colors.green.shade900, Icons.workspace_premium),
            _buildGradeScaleItem('A', '20-25%', Colors.green.shade700, Icons.emoji_events),
            _buildGradeScaleItem('B', '18-20%', Colors.lightGreen.shade700, Icons.sentiment_satisfied_alt),
            _buildGradeScaleItem('C', '15-18%', Colors.amber.shade700, Icons.sentiment_satisfied),
            _buildGradeScaleItem('D', '10-15%', Colors.orange.shade700, Icons.sentiment_neutral),
            _buildGradeScaleItem('E', '0-10%', Colors.red.shade700, Icons.sentiment_dissatisfied),
            _buildGradeScaleItem('F', '≤ 0%', Colors.red.shade900, Icons.sentiment_very_dissatisfied),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeScaleItem(String grade, String range, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                grade,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              range,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(icon, color: color, size: 24),
        ],
      ),
    );
  }
}