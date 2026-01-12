import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _pinController = TextEditingController();
  String _error = '';

  void _login() {
    if (_pinController.text == '1234') {
      context.go('/admin/console');
    } else {
      setState(() {
        _error = 'Invalid PIN. Try 1234.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.security, size: 64, color: AppColors.primary),
              const SizedBox(height: 16),
              const Text('Admin Access', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Enter Secure PIN to access Match Console', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
               const SizedBox(height: 32),
               TextField(
                 controller: _pinController,
                 obscureText: true,
                 textAlign: TextAlign.center,
                 keyboardType: TextInputType.number,
                 style: const TextStyle(fontSize: 24, letterSpacing: 8),
                 decoration: InputDecoration(
                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                   hintText: 'PIN',
                   errorText: _error.isNotEmpty ? _error : null,
                 ),
                 onSubmitted: (_) => _login(),
               ),
               const SizedBox(height: 24),
               SizedBox(
                 width: double.infinity,
                 height: 50,
                 child: ElevatedButton(
                   onPressed: _login,
                   style: ElevatedButton.styleFrom(
                     backgroundColor: AppColors.primary,
                     foregroundColor: Colors.white,
                   ),
                   child: const Text('ENTER CONSOLE'),
                 ),
               )
            ],
          ),
        ),
      ),
    );
  }
}
