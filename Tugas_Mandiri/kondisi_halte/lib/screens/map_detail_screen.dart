import 'package:kondisi_halte/models/post.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

//install depenencies flutter_map dan latlong2
class MapDetailScreen extends StatefulWidget {
  final Post post;
  const MapDetailScreen({super.key, required this.post});

  @override
  State<MapDetailScreen> createState() => _MapDetailScreenState();
}

class _MapDetailScreenState extends State<MapDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final lat = double.tryParse(widget.post.latitude ?? '');
    final lng = double.tryParse(widget.post.longitude ?? '');
    final hasLocation = lat != null && lng != null;
    final point = hasLocation ? LatLng(lat, lng) : const LatLng(0, 0);
    return Scaffold(
      appBar: AppBar(title: Text(widget.post.category ?? 'Map Detail')),
      body: hasLocation
          ? FlutterMap(
              options: MapOptions(initialCenter: point, initialZoom: 15),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.cepu_app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: point,
                      width: 48,
                      height: 48,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 48,
                      ),
                    ),
                  ],
                ),
              ],
            )
          : const Center(
              child: Text('No location data available for this post.'),
            ),
    );
  }
}