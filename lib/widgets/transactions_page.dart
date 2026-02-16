import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../utils/helpers.dart';
import 'transactions_card.dart';

class TransactionsPage extends StatelessWidget {
  final List<Transaction> transactions;
  final double totalExpense;
  final Function(Transaction) onTransactionTap;

  const TransactionsPage({
    Key? key,
    required this.transactions,
    required this.totalExpense,
    required this.onTransactionTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 2,
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_upward, color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        'Total Expense',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    Helpers.formatCurrency(totalExpense),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(child: _buildTransactionsList()),
      ],
    );
  }

  Widget _buildTransactionsList() {
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No transactions yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Transactions will appear here',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: transactions.length,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemBuilder: (context, index) {
        final transaction = transactions[transactions.length - 1 - index];
        return TransactionCard(
          transaction: transaction,
          onTap: () => onTransactionTap(transaction),
        );
      },
    );
  }
}