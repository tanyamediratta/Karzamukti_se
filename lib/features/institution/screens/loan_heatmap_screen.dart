// lib/features/govt/screens/loan_heatmap_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// VERY IMPORTANT: The ONLY correct import
import 'package:flutter_map_heatmap/flutter_map_heatmap.dart';

class LoanHeatmapScreen extends StatefulWidget {
  const LoanHeatmapScreen({super.key});

  @override
  State<LoanHeatmapScreen> createState() => _LoanHeatmapScreenState();
}

class _LoanHeatmapScreenState extends State<LoanHeatmapScreen> {
  final client = Supabase.instance.client;
  bool _loading = true;

  List<WeightedLatLng> _points = [];

  @override
  void initState() {
    super.initState();
    _loadPoints();
  }

  Future<void> _loadPoints() async {
    try {
      final rows = await client.from('loan_applications').select('latitude, longitude');

      final pts = <WeightedLatLng>[];

      for (var r in rows) {
        final lat = double.tryParse(r['latitude'].toString());
        final lon = double.tryParse(r['longitude'].toString());

        if (lat != null && lon != null) {
          pts.add(WeightedLatLng(LatLng(lat, lon), 1.0));
        }
      }

      if (pts.isEmpty) {
        pts.addAll(_samplePoints());
      }

      setState(() {
        _points = pts;
        _loading = false;
      });
    } catch (e) {
      debugPrint("Heatmap load error: $e");

      setState(() {
        _points = _samplePoints();
        _loading = false;
      });
    }
  }

  List<WeightedLatLng> _samplePoints() {
    return [
      WeightedLatLng(LatLng(28.6139, 77.2090), 1.0),
      WeightedLatLng(LatLng(19.0760, 72.8777), 1.0),
      WeightedLatLng(LatLng(22.5726, 88.3639), 1.0),
      WeightedLatLng(LatLng(13.0827, 80.2707), 1.0),
      WeightedLatLng(LatLng(12.9716, 77.5946), 1.0),
    ];
  }

  @override
  Widget build(BuildContext context) {
    const indiaCenter = LatLng(22.9734, 78.6569);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Loan Heatmap"),
        backgroundColor: Color(0xFFA8E6CF),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              options: const MapOptions(
                center: indiaCenter,
                zoom: 5,
                minZoom: 3,
                maxZoom: 13,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  userAgentPackageName: "karzamukti.app",
                ),

                /// ⭐ Correct Heatmap for flutter_map_heatmap 0.0.7
                HeatMapLayer(
                  heatMapOptions: HeatMapOptions(
                    radius: 45.0,
                    gradient:  {
                      0.1: Colors.blue,
                      0.3: Colors.green,
                      0.5: Colors.yellow,
                      0.7: Colors.orange,
                      1.0: Colors.red,
                    },
                  ),
                  heatMapDataSource: InMemoryHeatMapDataSource(
                    data: _points,
                  ),
                ),
              ],
            ),
    );
  }
}
