import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/platform_service.dart';
import '../services/storage_service.dart';
import '../services/tour_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../utils/tour_steps_data.dart';
import '../widgets/transactions_page.dart';
import '../widgets/budget_view.dart';
import '../widgets/expectations_view.dart';
import '../widgets/feature_tour_overlay.dart';
import '../widgets/tour_trigger_button.dart';
import '../widgets/grade_view.dart';
import 'category_group_detail_page.dart';
import '../notification_setup_guide.dart';
import '../widgets/ai_assistant_view.dart';
import '../widgets/rewards_page.dart';
import '../widgets/credit_simulator_page.dart';
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isServiceEnabled = false;
  bool hasOverlayPermission = false;
  double monthlyIncome = 0;
  Map<String, double> essentialExpenses = {};
  final List<Transaction> transactions = [];
  double savingsAmount = 0;
  int currentPage = 2;
  String savingsType = 'amount';
  List<double> pastMonthsExpenditure = [0, 0, 0];
  Set<String> userEssentialCategories = {};
  Map<String, dynamic> categoryCaps = {};
  bool _showTourBadge = false;

  // Getters
  double get totalExpense {
    return transactions
        .where((t) => t.type == 'DEBIT')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  Map<String, double> get expensesByCategory {
    final Map<String, double> categoryTotals = {};
    for (var transaction in transactions) {
      if (transaction.type == 'DEBIT') {
        categoryTotals[transaction.category] =
            (categoryTotals[transaction.category] ?? 0) + transaction.amount;
      }
    }
    return categoryTotals;
  }

  double get totalEssentialExpenses {
    return essentialExpenses.values.fold(0.0, (sum, value) => sum + value);
  }

  List<String> get dynamicEssentialCategories {
    const Map<String, String> categoryMapping = {
      'Laundry': 'Laundry',
      'Groceries': 'Groceries',
      'Mess/Food': 'Food',
      'Subscriptions': 'Bills',
      'Transport': 'Transport',
    };

    return userEssentialCategories
        .map((essentialName) => categoryMapping[essentialName] ?? essentialName)
        .toList();
  }

  List<String> get dynamicNonEssentialCategories {
    return AppConstants.categories
        .where((cat) => !dynamicEssentialCategories.contains(cat))
        .toList();
  }

  double get totalEssentialCategoryExpenses {
    return transactions
        .where((t) => t.type == 'DEBIT' && dynamicEssentialCategories.contains(t.category))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalNonEssentialCategoryExpenses {
    return transactions
        .where((t) => t.type == 'DEBIT' && dynamicNonEssentialCategories.contains(t.category))
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get remainingSavings {
    return monthlyIncome - totalExpense;
  }

  double get averagePastExpenditure {
    final validExpenditures = pastMonthsExpenditure.where((e) => e > 0).toList();
    return validExpenditures.isEmpty
        ? 0.0
        : validExpenditures.reduce((a, b) => a + b) / validExpenditures.length;
  }

  double get recommendedEssentialBudget {
    return monthlyIncome * 0.50;
  }

  double get recommendedNonEssentialBudget {
    return monthlyIncome * 0.30;
  }

  double get recommendedSavings {
    return monthlyIncome * 0.20;
  }

  double get totalOnboardingEssentialBudget {
    return totalEssentialExpenses;
  }

  List<Transaction> get debitTransactions {
    return transactions.where((t) => t.type == 'DEBIT').toList();
  }

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _checkServiceStatus();
    await _checkOverlayPermission();
    await _loadSavedTransactions();
    _listenToTransactions();
    _setupMethodChannel();
    _checkAndShowTour();
  }

  Future<void> _checkAndShowTour() async {
    final tourCompleted = await TourService.isTourCompleted();
    
    if (!tourCompleted) {
      setState(() {
        _showTourBadge = true;
      });
      
      // Auto-show tour after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _startTour();
        }
      });
    }
  }

  void _startTour() {
    setState(() {
      _showTourBadge = false;
    });
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => FeatureTourOverlay(
        steps: TourStepsData.getHomeTourSteps(),
        onPageChange: (int pageIndex) {
          // Navigate to the specified page
          if (mounted) {
            setState(() {
              currentPage = pageIndex;
            });
          }
        },
        onComplete: () async {
          await TourService.markTourCompleted();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('ðŸŽ‰ Tour completed! Start managing your expenses.'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
          }
        },
        onSkip: () async {
          await TourService.markTourCompleted();
        },
      ),
    );
  }

  void _setupMethodChannel() {
    PlatformService.setupMethodCallHandler((category) {
      if (mounted) {
        _openCategoryPage(category);
      }
    });
  }

  void _openCategoryPage(String category) {
    final isEssential = dynamicEssentialCategories.contains(category);

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
          onSaveCaps: (Map<String, dynamic> newCaps) {
            setState(() {
              categoryCaps = newCaps;
            });
            _saveCategoryCaps();
          },
          essentialExpenses: essentialExpenses,
          essentialCategories: dynamicEssentialCategories,
          nonEssentialCategories: dynamicNonEssentialCategories,
          recommendedNonEssentialBudget: recommendedNonEssentialBudget,
        ),
      ),
    );
  }

  Future<void> _loadSavedTransactions() async {
    try {
      final savedTransactions = await StorageService.loadTransactions();
      final userDataMap = await StorageService.loadUserData();

      setState(() {
        transactions.clear();
        transactions.addAll(savedTransactions);

        monthlyIncome = (userDataMap['monthly_income'] as num?)?.toDouble() ?? 0.0;

        if (userDataMap['essential_expenses'] != null) {
          final essentialExpensesData = userDataMap['essential_expenses'] as Map<String, dynamic>;
          essentialExpenses = essentialExpensesData.map((key, value) => MapEntry(key, (value as num).toDouble()));
          userEssentialCategories = essentialExpensesData.keys.toSet();
        }

        if (userDataMap['category_caps'] != null) {
          categoryCaps = Map<String, dynamic>.from(userDataMap['category_caps']);
          print('âœ… Category caps loaded: $categoryCaps');
        } else {
          print('âš ï¸ No category caps found in user data');
        }

        savingsAmount = (userDataMap['savings_amount'] as num?)?.toDouble() ?? 0.0;
        savingsType = userDataMap['savings_type'] as String? ?? 'amount';

        if (userDataMap['past_months_expenditure'] != null) {
          final pastExpenses = userDataMap['past_months_expenditure'] as List;
          pastMonthsExpenditure = pastExpenses.map((e) => (e as num).toDouble()).toList();
        }

        print('âœ… Loaded ${transactions.length} saved transactions');
        print('ðŸ“Š Monthly income: $monthlyIncome');
        print('ðŸ·ï¸ Essential expenses: $essentialExpenses');
      });

      _checkAllCategoryCaps();
    } catch (e) {
      print('âŒ Error loading saved transactions: $e');
    }
  }

  Future<void> _saveCategoryCaps() async {
    await PlatformService.saveCategoryCaps(categoryCaps);
  }

  void _checkAllCategoryCaps() {
    final categoryTotals = expensesByCategory;
    categoryTotals.forEach((category, spending) {
      _checkCategoryCapWarning(category, spending);
    });
  }

  void _checkCategoryCapWarning(String category, double currentSpending) {
    if (!categoryCaps.containsKey(category)) return;

    final capConfig = categoryCaps[category] as Map<String, dynamic>;
    final capType = capConfig['type'] as String;
    final capValue = (capConfig['value'] as num).toDouble();

    double capAmount;
    if (capType == 'percentage') {
      final onboardingLimit = Helpers.getOnboardingLimit(
        category,
        essentialExpenses,
        dynamicNonEssentialCategories,
        recommendedNonEssentialBudget,
      );
      if (onboardingLimit != null) {
        capAmount = onboardingLimit * capValue / 100;
      } else {
        capAmount = monthlyIncome * capValue / 100;
      }
    } else {
      capAmount = capValue;
    }

    final percentageUsed = (currentSpending / capAmount * 100);
    if (percentageUsed >= 80 && percentageUsed < 100) {
      _sendCapWarningNotification(category, currentSpending, capAmount, percentageUsed, 'warning');
    } else if (percentageUsed >= 100) {
      _sendCapWarningNotification(category, currentSpending, capAmount, percentageUsed, 'exceeded');
    }
  }

  Future<void> _sendCapWarningNotification(
    String category,
    double current,
    double cap,
    double percentage,
    String type,
  ) async {
    await PlatformService.sendCapWarningNotification(
      category: category,
      currentSpending: current,
      capAmount: cap,
      percentage: percentage,
      type: type,
    );
  }

  Future<void> _checkOverlayPermission() async {
    final result = await PlatformService.checkOverlayPermission();
    setState(() {
      hasOverlayPermission = result;
    });
  }

  Future<void> _requestOverlayPermission() async {
    await PlatformService.requestOverlayPermission();
    await Future.delayed(const Duration(seconds: 1));
    _checkOverlayPermission();
  }

  Future<void> _checkServiceStatus() async {
    final result = await PlatformService.isNotificationServiceEnabled();
    setState(() {
      isServiceEnabled = result;
    });
  }

  Future<void> _openSettings() async {
    await PlatformService.openNotificationSettings();
    await Future.delayed(const Duration(seconds: 1));
    _checkServiceStatus();
  }

  void _listenToTransactions() {
    PlatformService.transactionChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        print('Transaction received: $event');

        final Map<String, dynamic> data = Map<String, dynamic>.from(event as Map);

        if (data['isCategorized'] == true) {
          final id = data['id'].toString();
          setState(() {
            final index = transactions.indexWhere((t) => t.id == id);
            if (index != -1) {
              transactions[index].category = data['category'] as String;
            }
          });

          final newCategory = data['category'] as String;
          if (newCategory != 'Uncategorized') {
            final currentSpending = expensesByCategory[newCategory] ?? 0.0;
            _checkCategoryCapWarning(newCategory, currentSpending);
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Categorized as ${data['category']}'),
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          final category = data['category'] as String? ?? 'Uncategorized';
          final transaction = Transaction(
            id: data['timestamp'].toString(),
            type: data['type'] as String,
            amount: double.parse(data['amount'].toString()),
            merchant: data['merchant'] as String,
            account: data['account'].toString(),
            bank: data['bank'] as String,
            balance: data['balance'] as String? ?? 'N/A',
            timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int),
            category: category,
          );

          setState(() {
            transactions.add(transaction);
          });

          if (category != 'Uncategorized') {
            final currentSpending = expensesByCategory[category] ?? 0.0;
            _checkCategoryCapWarning(category, currentSpending);
          }

          if (category != 'Uncategorized' && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Auto-categorized as $category'),
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.blue,
              ),
            );
          }
        }
      },
      onError: (dynamic error) {
        print('Error receiving transaction: $error');
      },
    );
  }

  void _showCategoryDialog(Transaction transaction) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Categorize Expense'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Helpers.formatCurrency(transaction.amount),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                transaction.merchant,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              const Text(
                'Select Category:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ],
          ),
          actions: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.categories.map((category) {
                return ElevatedButton(
                  onPressed: () {
                    setState(() {
                      transaction.category = category;
                    });
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.getCategoryColor(category),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(category),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        actions: [
          TourTriggerButton(
            onPressed: _startTour,
            showBadge: _showTourBadge,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkServiceStatus,
          ),
        ],
      ),
      drawer: Drawer(
  child: ListView(
    padding: EdgeInsets.zero,
    children: [
      const DrawerHeader(
        decoration: BoxDecoration(
          color: Colors.blue,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.account_balance_wallet, size: 48, color: Colors.white),
            SizedBox(height: 12),
            Text(
              'Expense Tracker',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      // Main pages with selected state
      ListTile(
        leading: const Icon(Icons.trending_up),
        title: const Text('Budget Goals'),
        selected: currentPage == 2,
        onTap: () {
          setState(() {
            currentPage = 2;
          });
          Navigator.pop(context);
        },
      ),
      ListTile(
        leading: const Icon(Icons.grade),
        title: const Text('My Grade'),
        selected: currentPage == 3,
        onTap: () {
          setState(() {
            currentPage = 3;
          });
          Navigator.pop(context);
        },
      ),
      ListTile(
        leading: const Icon(Icons.list),
        title: const Text('Transactions'),
        selected: currentPage == 0,
        onTap: () {
          setState(() {
            currentPage = 0;
          });
          Navigator.pop(context);
        },
      ),
      ListTile(
        leading: const Icon(Icons.account_balance_wallet),
        title: const Text('Budget'),
        selected: currentPage == 1,
        onTap: () {
          setState(() {
            currentPage = 1;
          });
          Navigator.pop(context);
        },
      ),
      const Divider(),
      // Navigation pages (no selected state)
      ListTile(
        leading: const Icon(Icons.psychology),
        title: const Text('AI Assistant'),
        onTap: () {
          Navigator.pop(context); // Close drawer first
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AIAssistantView()),
          );
        },
      ),
      ListTile(
        leading: const Icon(Icons.card_giftcard),
        title: const Text('Rewards'),
        onTap: () {
          Navigator.pop(context); // Close drawer first
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RewardsPage()),
          );
        },
      ),
      ListTile(
        leading: const Icon(Icons.credit_card),
        title: const Text('Credit Simulator'),
        onTap: () {
          Navigator.pop(context); // Close drawer first
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreditSimulatorPage()),
          );
        },
      ),
      const Divider(),
      ListTile(
        leading: const Icon(Icons.help_outline),
        title: const Text('Restart App Tour'),
        onTap: () {
          Navigator.pop(context);
          _startTour();
        },
      ),
    ],
  ),
),
      body: Column(
        children: [
          if (!isServiceEnabled)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.orange.shade100,
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber, color: Colors.orange),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Notification access required to track transactions',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _openSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Enable'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const NotificationSetupGuide()),
                          );
                        },
                        icon: const Icon(Icons.help_outline, size: 18),
                        label: const Text('Setup Guide'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          if (isServiceEnabled && !hasOverlayPermission)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.red.shade100,
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.red),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Display over other apps permission required for category popup',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _requestOverlayPermission,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Allow'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: IndexedStack(
              index: currentPage.clamp(0, 3),
              children: [
                TransactionsPage(
                  transactions: debitTransactions,
                  totalExpense: totalExpense,
                  onTransactionTap: _showCategoryDialog,
                ),
                BudgetView(
                  monthlyIncome: monthlyIncome,
                  totalExpense: totalExpense,
                  essentialExpenses: essentialExpenses,
                  savings: remainingSavings > 0 ? remainingSavings : 0.0,
                  essential: totalEssentialCategoryExpenses,
                  nonEssential: totalNonEssentialCategoryExpenses,
                ),
                ExpectationsView(
                  monthlyIncome: monthlyIncome,
                  averagePastExpenditure: averagePastExpenditure,
                  savingsAmount: savingsAmount,
                  savingsType: savingsType,
                  totalEssentialCategoryExpenses: totalEssentialCategoryExpenses,
                  totalNonEssentialCategoryExpenses: totalNonEssentialCategoryExpenses,
                  totalOnboardingEssentialBudget: totalOnboardingEssentialBudget,
                  recommendedNonEssentialBudget: recommendedNonEssentialBudget,
                  recommendedSavings: recommendedSavings,
                  dynamicEssentialCategories: dynamicEssentialCategories,
                  dynamicNonEssentialCategories: dynamicNonEssentialCategories,
                  transactions: transactions,
                  categoryCaps: categoryCaps,
                  essentialExpenses: essentialExpenses,
                  onSaveCaps: (Map<String, dynamic> newCaps) {
                    setState(() {
                      categoryCaps = newCaps;
                    });
                    _saveCategoryCaps();
                  },
                ),
                GradeView(
        monthlyIncome: monthlyIncome,
        totalExpense: totalExpense,
        savings: remainingSavings,
      ),
              ],
            ),
          ),
        ],
      ),
    );
}
}