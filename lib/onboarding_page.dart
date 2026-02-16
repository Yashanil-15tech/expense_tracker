import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  double savingsAmount = 0;
  String savingsType = 'percentage';

  String userName = '';
  double monthlyIncome = 0;
  List<double> pastMonthsExpenditure = [0, 0, 0];
  Map<String, double> essentialExpenses = {};

  final TextEditingController _savingsController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _incomeController = TextEditingController();
  final List<TextEditingController> _expenditureControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  final List<Map<String, dynamic>> essentialCategories = [
    {'name': 'Laundry', 'icon': '🧺', 'frequency': 'weekly', 'options': [200.0, 250.0, 300.0, 350.0, 400.0]},
    {'name': 'Groceries', 'icon': '🛒', 'frequency': 'weekly', 'options': [500.0, 750.0, 1000.0, 1250.0, 1500.0]},
    {'name': 'Mess/Food', 'icon': '🍽️', 'frequency': 'monthly', 'options': [2000.0, 2500.0, 3000.0, 3500.0, 4000.0]},
    {'name': 'Subscriptions', 'icon': '📱', 'frequency': 'monthly', 'options': [200.0, 400.0, 600.0, 800.0, 1000.0]},
    {'name': 'Transport', 'icon': '🚗', 'frequency': 'weekly', 'options': [100.0, 200.0, 300.0, 400.0, 500.0]},
  ];

  Set<String> selectedCategories = {};
  Map<String, double> categoryAmounts = {};
  Map<String, TextEditingController> customAmountControllers = {};

  static const platform = MethodChannel('notification_listener_channel');

  @override
  void dispose() {
    _nameController.dispose();
    _incomeController.dispose();
    for (var controller in _expenditureControllers) {
      controller.dispose();
    }
    for (var controller in customAmountControllers.values) {
      controller.dispose();
    }
    _pageController.dispose();
    _savingsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: LinearProgressIndicator(
                value: (_currentPage + 1) / 9,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation(Colors.blue),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildWelcomePage(),
                  _buildIncomePage(),
                  _buildPastExpenditurePage(),
                  _buildCategoryInfoPagePlaceholder(),
                  _buildEssentialCategoriesPage(),
                  _buildEssentialAmountsPage(),
                  _buildSavingsInfoPagePlaceholder(),
                  _buildSavingsPage(),
                  _buildSummaryPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryInfoPagePlaceholder() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.lightbulb_outline, color: Colors.blue, size: 64),
            const SizedBox(height: 20),
            const Text('Understanding Your Spending', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('Before we continue, let\'s categorize your expenses.', style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 24),
            _buildInfoCard(icon: Icons.shopping_bag_outlined, title: 'Essential Expenses', description: 'Necessary spending like food, rent, utilities, and transportation.'),
            const SizedBox(height: 12),
            _buildInfoCard(icon: Icons.videogame_asset_outlined, title: 'Non-Essential Expenses', description: 'Discretionary spending like entertainment, dining out, and hobbies.'),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade200)),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 24),
                  const SizedBox(width: 12),
                  Expanded(child: Text('This helps you realize where your money is actually going and identify areas to optimize.', style: TextStyle(color: Colors.grey[700], fontSize: 14))),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildNavigationRow(onBack: () => _pageController.previousPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOut), onNext: () => _pageController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOut), nextLabel: 'Start Categorizing'),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSavingsInfoPagePlaceholder() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.savings_outlined, color: Colors.blue, size: 64),
            const SizedBox(height: 24),
            const Text('Setting Your Savings Goal', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('As a college student, building a savings habit is crucial for your financial future.', style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.blue, width: 2)),
              child: Column(
                children: [
                  const Text('20%', style: TextStyle(color: Colors.blue, fontSize: 48, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Recommended Savings Rate', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('For College Students', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildBenefitItem('Build emergency fund for unexpected expenses'),
            _buildBenefitItem('Develop long-term financial discipline'),
            _buildBenefitItem('Reduce financial stress and dependency'),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.shade200)),
              child: Row(
                children: [
                  const Icon(Icons.trending_up, color: Colors.orange, size: 24),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Try to aim for 20% or more. Every bit counts!', style: TextStyle(color: Colors.grey[700], fontSize: 14, fontWeight: FontWeight.w500))),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildNavigationRow(onBack: () => _pageController.previousPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOut), onNext: () => _pageController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOut), nextLabel: 'Set My Savings Goal'),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            SizedBox(height: 40),
            Text('👋', style: TextStyle(fontSize: 80)),
            SizedBox(height: 24),
            Text('Welcome to Expense Tracker!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            SizedBox(height: 16),
            Text('Let\'s set up your budget in a few simple steps', style: TextStyle(fontSize: 16, color: Colors.grey[600]), textAlign: TextAlign.center),
            SizedBox(height: 48),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'What\'s your name?', hintText: 'Enter your name', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: Icon(Icons.person)),
              textCapitalization: TextCapitalization.words,
              onChanged: (value) => setState(() => userName = value.trim()),
            ),
            SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: userName.isNotEmpty ? () => _pageController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOut) : null,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, disabledBackgroundColor: Colors.grey[300], disabledForegroundColor: Colors.grey[600], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomePage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            SizedBox(height: 40),
            Text('💰', style: TextStyle(fontSize: 80)),
            SizedBox(height: 24),
            Text('What\'s your monthly income?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            SizedBox(height: 16),
            Text('This could be pocket money, allowance, or stipend', style: TextStyle(fontSize: 16, color: Colors.grey[600]), textAlign: TextAlign.center),
            SizedBox(height: 48),
            TextField(
              controller: _incomeController,
              decoration: InputDecoration(labelText: 'Monthly Income', hintText: 'Enter amount', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: Icon(Icons.currency_rupee), suffixText: '/ month'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) => setState(() => monthlyIncome = double.tryParse(value) ?? 0),
            ),
            SizedBox(height: 32),
            _buildNavigationRow(onBack: () => _pageController.previousPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOut), onNext: monthlyIncome > 0 ? () => _pageController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOut) : null),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPastExpenditurePage() {
    final months = ['Last Month', '2 Months Ago', '3 Months Ago'];
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            SizedBox(height: 40),
            Text('📊', style: TextStyle(fontSize: 80)),
            SizedBox(height: 24),
            Text('Past Monthly Expenditure', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            SizedBox(height: 16),
            Text('Enter your total spending for the last 3 months', style: TextStyle(fontSize: 16, color: Colors.grey[600]), textAlign: TextAlign.center),
            SizedBox(height: 48),
            ...List.generate(3, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: TextField(
                  controller: _expenditureControllers[index],
                  decoration: InputDecoration(labelText: months[index], hintText: 'Enter amount', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: Icon(Icons.calendar_today), suffixText: '₹'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) => setState(() => pastMonthsExpenditure[index] = double.tryParse(value) ?? 0),
                ),
              );
            }),
            SizedBox(height: 16),
            if (pastMonthsExpenditure.any((e) => e > 0))
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Text('Average: ₹${(pastMonthsExpenditure.reduce((a, b) => a + b) / pastMonthsExpenditure.where((e) => e > 0).length).toStringAsFixed(0)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                  ],
                ),
              ),
            SizedBox(height: 32),
            _buildNavigationRow(onBack: () => _pageController.previousPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOut), onNext: pastMonthsExpenditure.any((e) => e > 0) ? () => _pageController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOut) : null),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildEssentialCategoriesPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          SizedBox(height: 8),
          Text('📋', style: TextStyle(fontSize: 24)),
          SizedBox(height: 12),
          Text('Choose your essential expenses', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          SizedBox(height: 8),
          Text('Drag categories into the Essential Expenses envelope', style: TextStyle(fontSize: 14, color: Colors.grey[600]), textAlign: TextAlign.center),
          SizedBox(height: 12),
          DragTarget<Map<String, dynamic>>(
            onWillAccept: (data) => data != null,
            onAccept: (data) {
              setState(() {
                if (!selectedCategories.contains(data['name'])) {
                  selectedCategories.add(data['name']);
                }
              });
            },
            builder: (context, candidateData, rejectedData) {
              final isHovering = candidateData.isNotEmpty;
              return AnimatedContainer(
                duration: Duration(milliseconds: 300),
                constraints: BoxConstraints(maxHeight: 140),
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isHovering ? Colors.blue.withOpacity(0.2) : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isHovering ? Colors.blue : Colors.blue.shade300, width: isHovering ? 3 : 2),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.mail_outline, size: 28, color: Colors.blue),
                        SizedBox(width: 10),
                        Text('Essential Expenses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                      ],
                    ),
                    SizedBox(height: 8),
                    Flexible(
                      child: SingleChildScrollView(
                        child: selectedCategories.isEmpty
                            ? Padding(padding: const EdgeInsets.all(12.0), child: Text('Drop categories here', style: TextStyle(fontSize: 14, color: Colors.grey[600], fontStyle: FontStyle.italic)))
                            : Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: selectedCategories.map((categoryName) {
                                  final category = essentialCategories.firstWhere((cat) => cat['name'] == categoryName);
                                  return Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                    decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(20)),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(category['icon'], style: TextStyle(fontSize: 13)),
                                        SizedBox(width: 4),
                                        Text(category['name'], style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11)),
                                        SizedBox(width: 3),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              selectedCategories.remove(categoryName);
                                              categoryAmounts.remove(categoryName);
                                              customAmountControllers[categoryName]?.dispose();
                                              customAmountControllers.remove(categoryName);
                                            });
                                          },
                                          child: Icon(Icons.close, size: 13, color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          SizedBox(height: 12),
          Text('Available Categories', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[700])),
          SizedBox(height: 8),
          Expanded(
            flex: 2,
            child: ListView.builder(
              itemCount: essentialCategories.length,
              itemBuilder: (context, index) {
                final category = essentialCategories[index];
                final isSelected = selectedCategories.contains(category['name']);
                
                if (isSelected) {
                  return Opacity(
                    opacity: 0.4,
                    child: Card(
                      margin: EdgeInsets.only(bottom: 6),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Row(
                          children: [
                            Text(category['icon'], style: TextStyle(fontSize: 20)),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(category['name'], style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                  Text('Paid ${category['frequency']}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                ],
                              ),
                            ),
                            Icon(Icons.check_circle, color: Colors.green),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return Draggable<Map<String, dynamic>>(
                  data: category,
                  feedback: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 250,
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))]),
                      child: Row(
                        children: [
                          Text(category['icon'], style: TextStyle(fontSize: 20)),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(category['name'], style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                Text('Paid ${category['frequency']}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.3,
                    child: Card(
                      margin: EdgeInsets.only(bottom: 6),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Row(
                          children: [
                            Text(category['icon'], style: TextStyle(fontSize: 20)),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(category['name'], style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                  Text('Paid ${category['frequency']}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  child: Card(
                    margin: EdgeInsets.only(bottom: 6),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Row(
                        children: [
                          Text(category['icon'], style: TextStyle(fontSize: 20)),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(category['name'], style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                Text('Paid ${category['frequency']}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                              ],
                            ),
                          ),
                          Icon(Icons.drag_indicator, color: Colors.grey[400], size: 18),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 12),
          _buildNavigationRow(onBack: () => _pageController.previousPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOut), onNext: selectedCategories.isNotEmpty ? () => _pageController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOut) : null),
        ],
      ),
    );
  }

  Widget _buildEssentialAmountsPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          SizedBox(height: 24),
          Text('💵', style: TextStyle(fontSize: 60)),
          SizedBox(height: 24),
          Text('Set your spending amounts', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          SizedBox(height: 16),
          Text('Choose from options or enter manually', style: TextStyle(fontSize: 16, color: Colors.grey[600]), textAlign: TextAlign.center),
          SizedBox(height: 32),
          Expanded(
            child: ListView.builder(
              itemCount: selectedCategories.length,
              itemBuilder: (context, index) {
                final categoryName = selectedCategories.elementAt(index);
                final category = essentialCategories.firstWhere((cat) => cat['name'] == categoryName);
                final options = category['options'] as List<double>;

                if (!customAmountControllers.containsKey(categoryName)) {
                  customAmountControllers[categoryName] = TextEditingController();
                }

                final hasCustomAmount = customAmountControllers[categoryName]!.text.isNotEmpty;

                return Card(
                  margin: EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(category['icon'], style: TextStyle(fontSize: 28)),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(category['name'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  Text(category['frequency'], style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: options.map((amount) {
                            final isSelected = categoryAmounts[categoryName] == amount && !hasCustomAmount;
                            return ChoiceChip(
                              label: Text('₹${amount.toInt()}'),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    categoryAmounts[categoryName] = amount;
                                    customAmountControllers[categoryName]?.clear();
                                  }
                                });
                              },
                              selectedColor: Colors.blue,
                              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                            );
                          }).toList(),
                        ),
                        SizedBox(height: 12),
                        TextField(
                          controller: customAmountControllers[categoryName],
                          decoration: InputDecoration(
                            labelText: 'Or enter custom amount',
                            hintText: 'Enter amount',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            prefixIcon: Icon(Icons.edit, size: 20),
                            suffixText: '₹',
                            isDense: true,
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          onChanged: (value) {
                            setState(() {
                              if (value.isNotEmpty) {
                                categoryAmounts[categoryName] = double.parse(value);
                              } else {
                                categoryAmounts.remove(categoryName);
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 16),
          _buildNavigationRow(onBack: () => _pageController.previousPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOut), onNext: categoryAmounts.length == selectedCategories.length ? () => _pageController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOut) : null),
        ],
      ),
    );
  }
Widget _buildSavingsPage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            SizedBox(height: 40),
            Text('💎', style: TextStyle(fontSize: 80)),
            SizedBox(height: 24),
            Text('How much do you want to save?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            SizedBox(height: 16),
            Text('Set your monthly savings goal', style: TextStyle(fontSize: 16, color: Colors.grey[600]), textAlign: TextAlign.center),
            SizedBox(height: 48),
            Container(
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {savingsType = 'amount'; _savingsController.clear(); savingsAmount = 0;}),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(color: savingsType == 'amount' ? Colors.blue : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                        child: Text('Fixed Amount', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: savingsType == 'amount' ? Colors.white : Colors.black)),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {savingsType = 'percentage'; _savingsController.clear(); savingsAmount = 0;}),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(color: savingsType == 'percentage' ? Colors.blue : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                        child: Text('Percentage', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: savingsType == 'percentage' ? Colors.white : Colors.black)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            TextField(
              controller: _savingsController,
              decoration: InputDecoration(
                labelText: savingsType == 'amount' ? 'Savings Amount' : 'Savings Percentage',
                hintText: 'Enter ${savingsType == 'amount' ? 'amount' : 'percentage'}',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: Icon(savingsType == 'amount' ? Icons.currency_rupee : Icons.percent),
                suffixText: savingsType == 'amount' ? '/ month' : '%',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) => setState(() => savingsAmount = double.tryParse(value) ?? 0),
            ),
            if (savingsAmount > 0 && savingsType == 'percentage')
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.shade200, width: 2)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                      SizedBox(width: 8),
                      Text('You\'ll save ₹${(monthlyIncome * savingsAmount / 100).toStringAsFixed(0)} per month', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green.shade900)),
                    ],
                  ),
                ),
              ),
            if (savingsAmount > 0 && savingsType == 'amount')
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.shade200, width: 2)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                      SizedBox(width: 8),
                      Text('That\'s ${((savingsAmount / monthlyIncome) * 100).toStringAsFixed(1)}% of your income', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green.shade900)),
                    ],
                  ),
                ),
              ),
            SizedBox(height: 32),
            _buildNavigationRow(onBack: () => _pageController.previousPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOut), onNext: savingsAmount > 0 ? () => _pageController.nextPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOut) : null),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryPage() {
    final totalEssential = categoryAmounts.values.fold(0.0, (sum, value) => sum + value);
    final savingsGoal = savingsType == 'percentage' ? (monthlyIncome * savingsAmount / 100) : savingsAmount;
    final remaining = monthlyIncome - totalEssential - savingsGoal;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          SizedBox(height: 24),
          Text('✅', style: TextStyle(fontSize: 60)),
          SizedBox(height: 24),
          Text('All Set, $userName!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          SizedBox(height: 16),
          Text('Here\'s your budget summary', style: TextStyle(fontSize: 16, color: Colors.grey[600]), textAlign: TextAlign.center),
          SizedBox(height: 32),
          Expanded(
            child: ListView(
              children: [
                _buildSummaryCard(icon: Icons.account_balance_wallet, iconColor: Colors.blue, title: 'Monthly Income', amount: monthlyIncome),
                SizedBox(height: 12),
                _buildSummaryCard(icon: Icons.savings, iconColor: Colors.green, title: 'Savings Goal', amount: savingsGoal, subtitle: savingsType == 'percentage' ? '${savingsAmount.toInt()}% of income' : 'Fixed amount'),
                SizedBox(height: 12),
                _buildSummaryCard(icon: Icons.shopping_cart, iconColor: Colors.orange, title: 'Essential Expenses', amount: totalEssential, subtitle: '${selectedCategories.length} categories'),
                SizedBox(height: 12),
                _buildSummaryCard(icon: Icons.account_balance, iconColor: remaining >= 0 ? Colors.purple : Colors.red, title: 'Available for Spending', amount: remaining, subtitle: remaining < 0 ? 'Budget deficit!' : 'Discretionary funds'),
              ],
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pageController.previousPage(duration: Duration(milliseconds: 300), curve: Curves.easeInOut),
                  style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text('Back'),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _completeOnboarding(),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text('Let\'s Start!'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String title, required String description}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(description, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.blue, size: 24),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }

  Widget _buildNavigationRow({required VoidCallback onBack, required VoidCallback? onNext, String nextLabel = 'Continue'}) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onBack,
            style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text('Back'),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: onNext,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text(nextLabel),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({required IconData icon, required Color iconColor, required String title, required double amount, String? subtitle}) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  if (subtitle != null) ...[
                    SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  ],
                ],
              ),
            ),
            Text('₹${amount.toStringAsFixed(0)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: iconColor)),
          ],
        ),
      ),
    );
  }

  Future<void> _completeOnboarding() async {
    essentialExpenses = {};
    for (var entry in categoryAmounts.entries) {
      final category = essentialCategories.firstWhere((cat) => cat['name'] == entry.key);
      final frequency = category['frequency'];
      final amount = entry.value;
      final monthlyAmount = frequency == 'weekly' ? amount * 4 : amount;
      essentialExpenses[entry.key] = monthlyAmount;
    }

    final validExpenditures = pastMonthsExpenditure.where((e) => e > 0).toList();
    final averagePastExpenditure = validExpenditures.isEmpty ? 0.0 : validExpenditures.reduce((a, b) => a + b) / validExpenditures.length;

    final userData = {
      'name': userName,
      'monthly_income': monthlyIncome,
      'past_months_expenditure': pastMonthsExpenditure,
      'average_past_expenditure': averagePastExpenditure,
      'essential_expenses': essentialExpenses,
      'onboarding_completed': true,
      'savings_amount': savingsAmount,
      'savings_type': savingsType,
    };

    try {
      await platform.invokeMethod('saveUserData', json.encode(userData));
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      print('Error saving user data: $e');
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Error'),
            content: Text('Failed to save your data. Please try again.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }
}
