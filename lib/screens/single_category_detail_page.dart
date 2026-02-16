import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../utils/helpers.dart';

class SingleCategoryDetailPage extends StatelessWidget {
  final String categoryName;
  final List<Transaction> transactions;
  final double totalAmount;
  final Color color;
  final IconData icon;
  final Map<String, dynamic> capInfo;

  const SingleCategoryDetailPage({
    Key? key,
    required this.categoryName,
    required this.transactions,
    required this.totalAmount,
    required this.color,
    required this.icon,
    required this.capInfo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(categoryName),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            color: color.withOpacity(0.1),
            child: Column(
              children: [
                Icon(icon, size: 48, color: color),
                SizedBox(height: 12),
                Text(
                  Helpers.formatCurrency(totalAmount, showDecimals: false),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  '${transactions.length} transactions',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                if (capInfo['hasCap']) ...[
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: capInfo['capColor'].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: capInfo['capColor'], width: 2),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_active, color: capInfo['capColor'], size: 20),
                            SizedBox(width: 8),
                            Text(
                              capInfo['message'],
                              style: TextStyle(
                                color: capInfo['capColor'],
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (totalAmount / capInfo['capAmount']).clamp(0.0, 1.0),
                            backgroundColor: Colors.grey[300],
                            color: capInfo['capColor'],
                            minHeight: 8,
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
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final t = transactions[transactions.length - 1 - index];
                return Card(
                  margin: EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(t.merchant),
                    subtitle: Text(Helpers.formatTime(t.timestamp)),
                    trailing: Text(
                      '-${Helpers.formatCurrency(t.amount)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
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
}