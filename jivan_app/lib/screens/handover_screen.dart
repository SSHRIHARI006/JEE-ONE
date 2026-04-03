import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:go_router/go_router.dart';

class HandoverScreen extends StatefulWidget {
  const HandoverScreen({super.key});

  @override
  State<HandoverScreen> createState() => _HandoverScreenState();
}

class _HandoverScreenState extends State<HandoverScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticating = false;
  String _authorized = 'Not Authorized';

  Future<void> _authenticate() async {
    bool authenticated = false;
    try {
      setState(() {
        _isAuthenticating = true;
        _authorized = 'Authenticating';
      });
      authenticated = await auth.authenticate(
        localizedReason: 'Scan Biometrics to confirm patient handover to hospital staff',
        options: const AuthenticationOptions(stickyAuth: true),
      );
      setState(() {
        _isAuthenticating = false;
        _authorized = authenticated ? 'Authorized' : 'Not Authorized';
      });
      
      if (authenticated && mounted) {
        // Handover complete, return to home
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Handover Confirmed Successfully'), backgroundColor: Colors.green),
        );
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) context.go('/');
        });
      }
    } catch (e) {
      setState(() {
        _isAuthenticating = false;
        _authorized = 'Error - $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hospital Handover')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.medical_services, size: 100, color: Colors.grey),
            const SizedBox(height: 32),
            Text('Status: $_authorized', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.fingerprint, size: 32),
              label: const Text('Confirm Handover (Biometric)'),
              onPressed: _isAuthenticating ? null : _authenticate,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
