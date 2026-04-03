import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/emergency_provider.dart';

class HospitalListScreen extends StatelessWidget {
  const HospitalListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmergencyProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Recommended Facilities')),
      body: provider.isLoadingRecommendations
          ? const Center(child: CircularProgressIndicator())
          : provider.recommendations.isEmpty
              ? _buildMockFallback(context)
              : ListView.builder(
                  itemCount: provider.recommendations.length,
                  itemBuilder: (context, index) {
                    final hospital = provider.recommendations[index];
                    final isHighLoad = hospital.currentLoadPercentage > 80;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(hospital.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            if (isHighLoad)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text('High Load', style: TextStyle(color: Colors.red, fontSize: 12)),
                              ),
                          ],
                        ),
                        subtitle: Text('ETA: ${hospital.etaMinutes} min • ICU Beds: ${hospital.availableIcuBeds}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.info_outline),
                          onPressed: () => _showExplainability(context, hospital.specialty),
                        ),
                        onTap: () {
                          // Note: In real app, we'd pass the hospital ID to the route
                          context.push('/navigation');
                        },
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildMockFallback(BuildContext context) {
    // Shows if backend fails or during dev
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Could not fetch recommendations.'),
          TextButton(
            onPressed: () => context.push('/navigation'),
            child: const Text('Proceed to Mock Map Route'),
          ),
        ],
      ),
    );
  }

  void _showExplainability(BuildContext context, String specialty) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Why this hospital?', style: Theme.of(context).textTheme.displayMedium),
              const SizedBox(height: 16),
              const Text('The AI routed to this hospital because:'),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: Text('Nearest facility with active $specialty specialist'),
              ),
              const ListTile(
                leading: Icon(Icons.check_circle, color: Colors.green),
                title: Text('Fastest ETA via OpenRouteService traffic data'),
              ),
            ],
          ),
        );
      },
    );
  }
}
