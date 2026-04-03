import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/emergency_provider.dart';

class EmergencyReportingScreen extends StatelessWidget {
  const EmergencyReportingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Emergency Type')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildEmergenyCard(context, 'Accident', Icons.car_crash),
            _buildEmergenyCard(context, 'Cardiac', Icons.favorite),
            _buildEmergenyCard(context, 'Respiratory', Icons.air),
            _buildEmergenyCard(context, 'Other', Icons.warning),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergenyCard(BuildContext context, String type, IconData icon) {
    return GestureDetector(
      onTap: () {
        context.read<EmergencyProvider>().reportIncidentType(type);
        context.push('/intake');
      },
      child: Card(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Theme.of(context).primaryColor),
            const SizedBox(height: 16),
            Text(type, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
