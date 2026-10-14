import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class SatelliteMeasureScreen extends StatefulWidget {
  final double initialLat;
  final double initialLng;
  final String namaLahan;

  const SatelliteMeasureScreen({
    super.key,
    required this.initialLat,
    required this.initialLng,
    required this.namaLahan,
  });

  @override
  State<SatelliteMeasureScreen> createState() => _SatelliteMeasureScreenState();
}

class _SatelliteMeasureScreenState extends State<SatelliteMeasureScreen> {
  static const Color primaryGreen = Color(0xFF16A34A);

  late final MapController _mapController;
  final List<LatLng> _polygonPoints = [];
  bool _isSatelliteLayer = true;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  // Hitung luas poligon bola bumi (Spherical Polygon Geodesic Area in m²)
  double _calculatePolygonArea(List<LatLng> points) {
    if (points.length < 3) return 0.0;

    const double earthRadius = 6378137.0; // Jari-jari bumi dalam meter
    double total = 0.0;

    for (int i = 0; i < points.length; i++) {
      final p1 = points[i];
      final p2 = points[(i + 1) % points.length];

      final double lat1 = p1.latitude * math.pi / 180.0;
      final double lat2 = p2.latitude * math.pi / 180.0;
      final double lon1 = p1.longitude * math.pi / 180.0;
      final double lon2 = p2.longitude * math.pi / 180.0;

      total += (lon2 - lon1) * (2.0 + math.sin(lat1) + math.sin(lat2));
    }

    final double area = total * earthRadius * earthRadius / 2.0;
    return area.abs();
  }

  void _addPoint(LatLng point) {
    setState(() {
      _polygonPoints.add(point);
    });
  }

  void _undoPoint() {
    if (_polygonPoints.isNotEmpty) {
      setState(() {
        _polygonPoints.removeLast();
      });
    }
  }

  void _clearPoints() {
    setState(() {
      _polygonPoints.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final double areaM2 = _calculatePolygonArea(_polygonPoints);
    final double areaHektar = areaM2 / 10000.0;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ukur Sawah Citra Satelit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(
              widget.namaLahan,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Ganti Tipe Peta',
            icon: Icon(_isSatelliteLayer ? Icons.satellite_alt : Icons.map),
            onPressed: () {
              setState(() {
                _isSatelliteLayer = !_isSatelliteLayer;
              });
            },
          ),
          IconButton(
            tooltip: 'Pusatkan ke Lahan',
            icon: const Icon(Icons.my_location),
            onPressed: () {
              _mapController.move(LatLng(widget.initialLat, widget.initialLng), 17.5);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Peta Interaktif FlutterMap
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(widget.initialLat, widget.initialLng),
              initialZoom: 17.5,
              maxZoom: 19.0,
              minZoom: 12.0,
              onTap: (tapPosition, point) => _addPoint(point),
            ),
            children: [
              // Tile Citra Satelit Esri World Imagery (High-Res Asli)
              TileLayer(
                urlTemplate: _isSatelliteLayer
                    ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                    : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.epupuk.mobile',
              ),

              // Garis Hubung Poligon Lahan
              if (_polygonPoints.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [..._polygonPoints, _polygonPoints.first],
                      color: const Color(0xFF22C55E),
                      strokeWidth: 3.0,
                    ),
                  ],
                ),

              // Area Poligon Hijau Transparan
              if (_polygonPoints.length >= 3)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: _polygonPoints,
                      color: const Color(0x6616A34A),
                      borderColor: const Color(0xFF16A34A),
                      borderStrokeWidth: 2.5,
                      isFilled: true,
                    ),
                  ],
                ),

              // Titik Pin Sudut Pematang Sawah
              MarkerLayer(
                markers: _polygonPoints.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final point = entry.value;
                  return Marker(
                    point: point,
                    width: 32,
                    height: 32,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: primaryGreen, width: 2.5),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '$index',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: primaryGreen,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // 2. Banner Panduan Petugas PPL di Atas
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xDD0F172A),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 6),
                ],
              ),
              child: Row(
                children: const [
                  Icon(Icons.touch_app_rounded, color: Color(0xFF4ADE80), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Ketuk sudut-sudut petak sawah pada foto satelit untuk mengukur luas aktual.',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Panel Hasil Pengukuran & Tombol Aksi di Bawah
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Angka Luas Terukur
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Luas Sawah Terukur',
                            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                areaM2 > 0 ? areaM2.toStringAsFixed(1) : '0',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text('m²', style: TextStyle(fontWeight: FontWeight.bold, color: primaryGreen)),
                              const SizedBox(width: 10),
                              Text(
                                '(${areaHektar.toStringAsFixed(3)} Ha)',
                                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_polygonPoints.length} Titik Sudut',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF166534),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  // Tombol Undo & Reset
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.undo_rounded, size: 18),
                          label: const Text('Hapus Titik', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF4B5563),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          onPressed: _polygonPoints.isNotEmpty ? _undoPoint : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.delete_sweep_rounded, size: 18, color: Colors.red),
                          label: const Text('Reset', style: TextStyle(fontSize: 12, color: Colors.red)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          onPressed: _polygonPoints.isNotEmpty ? _clearPoints : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Tombol Gunakan Hasil Ukur
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                      label: const Text(
                        'Terapkan Luas ke Form Survei',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      onPressed: areaM2 > 0
                          ? () {
                              Navigator.pop(context, areaM2);
                            }
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
