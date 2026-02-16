import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class SetCategoryCapScreen extends StatefulWidget {
  final List<String> categories;
  final Map<String, dynamic> currentCaps;
  final Color color;
  final double monthlyIncome;
  final Function(Map<String, dynamic>) onSave;
  final Map<String, double> essentialExpenses;
  final List<String> essentialCategories;
  final List<String> nonEssentialCategories;
  final double recommendedNonEssentialBudget;

  const SetCategoryCapScreen({
    Key? key,
    required this.categories,
    required this.currentCaps,
    required this.color,
    required this.monthlyIncome,
    required this.onSave,
    required this.essentialExpenses,
    required this.essentialCategories,
    required this.nonEssentialCategories,
    required this.recommendedNonEssentialBudget,
  }) : super(key: key);

  @override
  State<SetCategoryCapScreen> createState() => _SetCategoryCapScreenState();
}

class _SetCategoryCapScreenState extends State<SetCategoryCapScreen> {
  late Map<String, dynamic> _caps;

  @override
  void initState() {
    super.initState();
    _caps = Map.from(widget.currentCaps);
  }

  void _showCapDialog(String category) {
    final TextEditingController amountController = TextEditingController();
    String selectedType = 'amount';

    if (_caps.containsKey(category)) {
      final capConfig = _caps[category] as Map<String, dynamic>;
      selectedType = capConfig['type'] as String;
      amountController.text = capConfig['value'].toString();
    }

    final onboardingLimit = Helpers.getOnboardingLimit(
      category,
      widget.essentialExpenses,
      widget.nonEssentialCategories,
      widget.recommendedNonEssentialBudget,
    );

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final inputValue = double.tryParse(amountController.text) ?? 0;
            double actualAmount;

            if (selectedType == 'percentage') {
              if (onboardingLimit != null) {
                actualAmount = onboardingLimit * inputValue / 100;
              } else {
                actualAmount = widget.monthlyIncome * inputValue / 100;
              }
            } else {
              actualAmount = inputValue;
            }

            final isValid = onboardingLimit == null || actualAmount <= onboardingLimit;

            return AlertDialog(
              title: Text('Set Cap for $category'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Set a spending limit for this category',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    if (onboardingLimit != null) ...[
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.blue, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Your ${widget.nonEssentialCategories.contains(category) ? "Non-Essential" : "Category"} Budget',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue[900],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 6),
                            Text(
                              Helpers.formatCurrency(onboardingLimit, showDecimals: false),
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.blue[900],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Cap must be ≤ this amount',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: Text('Amount', style: TextStyle(fontSize: 14)),
                            value: 'amount',
                            groupValue: selectedType,
                            onChanged: (value) {
                              setDialogState(() {
                                selectedType = value!;
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: Text('Percentage', style: TextStyle(fontSize: 14)),
                            value: 'percentage',
                            groupValue: selectedType,
                            onChanged: (value) {
                              setDialogState(() {
                                selectedType = value!;
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: selectedType == 'amount' ? 'Amount (₹)' : 'Percentage (%)',
                        border: OutlineInputBorder(),
                        prefixText: selectedType == 'amount' ? '₹ ' : '',
                        suffixText: selectedType == 'percentage' ? '%' : '',
                        helperText: selectedType == 'percentage' && onboardingLimit != null
                            ? 'Of your ${Helpers.formatCurrency(onboardingLimit, showDecimals: false)} budget'
                            : selectedType == 'percentage'
                                ? 'Of monthly income (${Helpers.formatCurrency(widget.monthlyIncome, showDecimals: false)})'
                                : onboardingLimit != null
                                    ? 'Max: ${Helpers.formatCurrency(onboardingLimit, showDecimals: false)}'
                                    : null,
                        errorText: !isValid && amountController.text.isNotEmpty ? 'Exceeds limit' : null,
                      ),
                      onChanged: (value) {
                        setDialogState(() {});
                      },
                    ),
                    if (selectedType == 'percentage' && amountController.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calculate, color: Colors.blue, size: 16),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  onboardingLimit != null
                                      ? 'Equivalent: ${Helpers.formatCurrency(actualAmount, showDecimals: false)} (${inputValue.toStringAsFixed(0)}% of ${Helpers.formatCurrency(onboardingLimit, showDecimals: false)})'
                                      : 'Equivalent: ${Helpers.formatCurrency(actualAmount, showDecimals: false)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue[900],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (onboardingLimit != null && amountController.text.isNotEmpty) ...[
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isValid ? Colors.green.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isValid ? Colors.green.shade200 : Colors.red.shade200,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isValid ? Icons.check_circle : Icons.error_outline,
                              color: isValid ? Colors.green : Colors.red,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isValid ? 'Valid Cap ✓' : 'Invalid Cap ✗',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isValid ? Colors.green[900] : Colors.red[900],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    isValid
                                        ? '${Helpers.formatCurrency(onboardingLimit - actualAmount, showDecimals: false)} remaining'
                                        : 'Exceeds by ${Helpers.formatCurrency(actualAmount - onboardingLimit, showDecimals: false)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isValid ? Colors.green[800] : Colors.red[800],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                if (_caps.containsKey(category))
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _caps.remove(category);
                      });
                      widget.onSave(_caps);
                      Navigator.of(dialogContext).pop();
                      Navigator.of(context).pop();
                    },
                    child: Text('Remove', style: TextStyle(color: Colors.red)),
                  ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: !isValid || amountController.text.isEmpty
                      ? null
                      : () async {
                          final value = double.tryParse(amountController.text);
                          if (value == null || value <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Please enter a valid amount'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          setState(() {
                            _caps[category] = {
                              'type': selectedType,
                              'value': value,
                            };
                          });

                          widget.onSave(_caps);

                          await Future.delayed(Duration(milliseconds: 100));

                          Navigator.of(dialogContext).pop();

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('✅ Cap set for $category: ${Helpers.formatCurrency(actualAmount, showDecimals: false)}'),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isValid ? widget.color : Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Set Spending Caps'),
        backgroundColor: widget.color,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop(true);
          },
        ),
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: widget.categories.length,
        itemBuilder: (context, index) {
          final category = widget.categories[index];
          final hasCap = _caps.containsKey(category);

          return Card(
            margin: EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppConstants.getCategoryColor(category).withOpacity(0.2),
                child: Icon(AppConstants.getCategoryIcon(category), color: AppConstants.getCategoryColor(category)),
              ),
              title: Text(category, style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: hasCap
                  ? Text('Cap: ${_caps[category]['type'] == 'percentage' ? '${_caps[category]['value']}%' : Helpers.formatCurrency(_caps[category]['value'], showDecimals: false)}')
                  : Text('No cap set'),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showCapDialog(category),
            ),
          );
        },
      ),
    );
  }
}