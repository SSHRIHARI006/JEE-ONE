import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/emergency_provider.dart';

class TriageResultScreen extends StatelessWidget {
  const TriageResultScreen({super.key});

  Color _getUrgencyColor(int severity) {
    if (severity >= 8) return Colors.red;
    if (severity >= 5) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final severity = context.select((EmergencyProvider p) => p.severity);
    final color = _getUrgencyColor(severity);

    return Scaffold(
      appBar: AppBar(title: const Text('Triage Result')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Severity Score', style: TextStyle(fontSize: 24, color: Colors.grey)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 8),
              ),
              child: Text(
                '$severity',
                style: TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: color),
              ),
            )
            .animate()
            .scale(duration: 500.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 32),
            Text(
              severity >= 8 ? 'CRITICAL - IMMEDIATE DISPATCH' : 'URGENT',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () {
                context.pushReplacement('/hospitals');
              },
              child: const Text('View Recommended Hospitals'),
            ),
          ],
        ),
      ),
    );
  }
}
