class Transaction {
  final String id;
  final String type;
  final double amount;
  final String merchant;
  final String account;
  final String bank;
  final String balance;
  final DateTime timestamp;
  String category;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.merchant,
    required this.account,
    required this.bank,
    required this.balance,
    required this.timestamp,
    this.category = 'Uncategorized',
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'].toString(),
      type: json['type'] as String,
      amount: double.parse(json['amount'].toString()),
      merchant: json['merchant'] as String,
      account: json['account'] as String,
      bank: json['bank'] as String,
      balance: json['balance'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      category: json['category'] as String? ?? 'Uncategorized',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'merchant': merchant,
      'account': account,
      'bank': bank,
      'balance': balance,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'category': category,
    };
  }
}