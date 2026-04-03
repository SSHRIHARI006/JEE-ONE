import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/emergency_provider.dart';

class CaseIntakeScreen extends StatefulWidget {
  const CaseIntakeScreen({super.key});

  @override
  State<CaseIntakeScreen> createState() => _CaseIntakeScreenState();
}

class _CaseIntakeScreenState extends State<CaseIntakeScreen> {
  final _formKey = GlobalKey<FormState>();
  double _spo2 = 98;
  double _heartRate = 80;
  double _sysBp = 120;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Patient Vitals')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'SpO2 (%)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                initialValue: _spo2.toString(),
                onChanged: (val) => _spo2 = double.tryParse(val) ?? 98,
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Heart Rate (BPM)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                initialValue: _heartRate.toString(),
                onChanged: (val) => _heartRate = double.tryParse(val) ?? 80,
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Systolic Blood Pressure', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                initialValue: _sysBp.toString(),
                onChanged: (val) => _sysBp = double.tryParse(val) ?? 120,
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // Start saving vitals & updating triage
                    context.read<EmergencyProvider>().updateVitals(
                      spo2: _spo2,
                      heartRate: _heartRate,
                      systolicBp: _sysBp,
                    );
                    // Fetch API in background
                    context.read<EmergencyProvider>().fetchHospitalRecommendations();
                    context.push('/triage-loading');
                  }
                },
                child: const Text('Analyze Vitals'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
