import 'package:flutter/material.dart';

class NotificationSetupGuide extends StatelessWidget {
  const NotificationSetupGuide({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Guide'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 32),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Notification Access Setup',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'To track your expenses automatically, please follow these steps:',
                    style: TextStyle(fontSize: 15),
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 16),
          
          _buildStep(
            '1',
            'Enable Notification Access',
            'Go to Settings → Apps → Expense Tracker → Notifications → Allow notification access',
            Icons.notifications,
            Colors.orange,
          ),
          
          _buildStep(
            '2',
            'Show Sensitive Content',
            'Go to Settings → Notifications → Notifications on lock screen → Show all content',
            Icons.lock_open,
            Colors.green,
          ),
          
          _buildStep(
            '3',
            'Disable "Hide Sensitive Content"',
            'Go to Settings → Security & privacy → Hide sensitive content → Turn OFF',
            Icons.visibility,
            Colors.blue,
          ),
          
          _buildStep(
            '4',
            'Allow Display Over Other Apps',
            'This allows category selection popup to appear',
            Icons.open_in_new,
            Colors.purple,
          ),
          
          SizedBox(height: 16),
          
          Card(
            color: Colors.amber.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'OnePlus/Oppo users: You may need to also disable "Private Safe" or "App Lock" for Messages app',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStep(String number, String title, String description, IconData icon, Color color) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color,
              foregroundColor: Colors.white,
              child: Text(number, style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 20, color: color),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
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
}