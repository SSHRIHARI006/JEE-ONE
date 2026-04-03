import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';

class TriageLoadingScreen extends StatefulWidget {
  const TriageLoadingScreen({super.key});

  @override
  State<TriageLoadingScreen> createState() => _TriageLoadingScreenState();
}

class _TriageLoadingScreenState extends State<TriageLoadingScreen> {
  @override
  void initState() {
    super.initState();
    // Simulate seamless loading animation before showing the result
    Timer(const Duration(seconds: 3), () {
      if (mounted) context.pushReplacement('/triage-result');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.healing,
              size: 100,
              color: Theme.of(context).primaryColor,
            )
                .animate(onPlay: (controller) => controller.repeat())
                .scaleXY(end: 1.2, duration: 600.ms)
                .then()
                .scaleXY(end: 1 / 1.2),
            const SizedBox(height: 32),
            const Text(
              'Running AI Triage...',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            )
                .animate(onPlay: (controller) => controller.repeat())
                .fade(duration: 800.ms)
                .then()
                .fade(begin: 1, end: 0.2),
          ],
        ),
      ),
    );
  }
}
