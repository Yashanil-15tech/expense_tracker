import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/platform_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _requestSmsPermission();
    _checkOnboarding();
  }

  Future<void> _requestSmsPermission() async {
    try {
      final status = await Permission.sms.request();
      if (status.isGranted) {
        print('SMS permission granted');
      } else if (status.isDenied) {
        print('SMS permission denied');
      } else if (status.isPermanentlyDenied) {
        print('SMS permission permanently denied');
      }
    } catch (e) {
      print('Error requesting SMS permission: $e');
    }
  }

  Future<void> _checkOnboarding() async {
    try {
      final bool isCompleted = await PlatformService.isOnboardingCompleted();
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        if (isCompleted) {
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          Navigator.of(context).pushReplacementNamed('/onboarding');
        }
      }
    } catch (e) {
      print('Error checking onboarding: $e');
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/onboarding');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet, size: 80, color: Colors.blue),
            SizedBox(height: 24),
            Text(
              'Expense Tracker',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}