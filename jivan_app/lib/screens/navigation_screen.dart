import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/emergency_provider.dart';
import '../services/location_service.dart';

class NavigationScreen extends StatelessWidget {
  const NavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<EmergencyProvider>();
    
    // Default to Pune MIT-WPU if something goes wrong
    final userLat = provider.currentPosition?.latitude ?? LocationService.fallbackLat;
    final userLng = provider.currentPosition?.longitude ?? LocationService.fallbackLng;
    
    final destinationLat = 18.5204; // Mock Hospital Lat (Pune general offset)
    final destinationLng = 73.8567; // Mock Hospital Lng
    
    final userPos = LatLng(userLat, userLng);
    final hospitalPos = LatLng(destinationLat, destinationLng);

    return Scaffold(
      appBar: AppBar(title: const Text('Fastest Route')),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: userPos,
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.jeevan.emergency',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [userPos, hospitalPos],
                    color: Theme.of(context).primaryColor,
                    strokeWidth: 5.0,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: userPos,
                    child: const Icon(Icons.my_location, color: Colors.blue, size: 40),
                  ),
                  Marker(
                    point: hospitalPos,
                    child: const Icon(Icons.local_hospital, color: Colors.red, size: 40),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(24),
              ),
              onPressed: () => context.push('/handover'),
              child: const Text('Arrived at Hospital - Handover'),
            ),
          )
        ],
      ),
    );
  }
}
