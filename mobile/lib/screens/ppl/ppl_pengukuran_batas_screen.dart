import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../config/theme.dart';
import '../../models/ppl_task_model.dart';
import '../../services/geo_calc_service.dart';
import '../../services/location_service.dart';
import 'ppl_hasil_pengukuran_screen.dart';

class BoundaryPointItem {
  final String code; // P1, P2, P3, P4, Pn
  final String title;
  final LatLng point;
  final String time;
  final String description;
  final String accuracy;
  final bool isValid;

  BoundaryPointItem({
    required this.code,
    required this.title,
    required this.point,
    required this.time,
    required this.description,
    required this.accuracy,
    this.isValid = true,
  });

  BoundaryPointItem copyWith({
    String? code,
    String? title,
    LatLng? point,
    String? time,
    String? description,
    String? accuracy,
    bool? isValid,
  }) {
    return BoundaryPointItem(
      code: code ?? this.code,
      title: title ?? this.title,
      point: point ?? this.point,
      time: time ?? this.time,
      description: description ?? this.description,
      accuracy: accuracy ?? this.accuracy,
      isValid: isValid ?? this.isValid,
    );
  }
}

class PPLPengukuranBatasScreen extends StatefulWidget {
  final PPLTaskModel task;

  const PPLPengukuranBatasScreen({super.key, required this.task});

  @override
  State<PPLPengukuranBatasScreen> createState() => _PPLPengukuranBatasScreenState();
}

class _PPLPengukuranBatasScreenState extends State<PPLPengukuranBatasScreen> {
  late final MapController _mapController;
  late PPLTaskModel _task;
  bool _isSatelliteLayer = true;
  bool _isCapturingGps = false;

  // Daftar titik batas tapak sawah yang terukur di lapangan
  late List<BoundaryPointItem> _points;

  // Lokasi real-time perangkat PPL
  LatLng? _deviceLocation;
  double? _deviceAccuracy;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _task = widget.task;

    // Muat titik batas dari data tersimpan sebelumnya jika ada
    // Gunakan parsedPolygonPoints agar aman untuk format String JSON maupun List
    final List<LatLng> savedPoints = _task.parsedPolygonPoints;
    if (savedPoints.isNotEmpty) {
      _points = savedPoints.asMap().entries.map((entry) {
        final int i = entry.key;
        final LatLng pt = entry.value;
        return BoundaryPointItem(
          code: 'P',
          title: 'Patok Batas P',
          point: pt,
          time: 'Tersimpan',
          description: 'Dimuat dari data survei sebelumnya',
          accuracy: '(tersimpan)',
        );
      }).toList();
    } else {
      // Mulai dari daftar kosong — PPL harus mengukur sendiri di lapangan
      _points = [];
    }
  }

  List<LatLng> get _latLngPoints => _points.map((p) => p.point).toList();

  double get _calculatedAreaM2 => GeoCalcService.calculateGeodesicArea(_latLngPoints);
  double get _calculatedPerimeterM => GeoCalcService.calculatePerimeter(_latLngPoints);

  // Status Geofencing: apakah lokasi perangkat saat ini di dalam bidang lahan?
  bool get _isInsideLand {
    if (_deviceLocation == null || _latLngPoints.length < 3) return true; // Default inside jika belum GPS
    return GeoCalcService.isPointInPolygon(_deviceLocation!, _latLngPoints);
  }

  /// Ambil posisi langsung dari hardware GPS
  Future<void> _captureDeviceGPS({bool addNewPoint = false}) async {
    setState(() => _isCapturingGps = true);

    final result = await LocationService.getCurrentLocation(timeout: const Duration(seconds: 8));

    if (!mounted) return;
    setState(() => _isCapturingGps = false);

    if (result.isSuccess && result.position != null) {
      final LatLng pos = result.position!;
      setState(() {
        _deviceLocation = pos;
        _deviceAccuracy = result.accuracy;

        if (addNewPoint) {
          final int nextNum = _points.length + 1;
          _points.add(BoundaryPointItem(
            code: 'P$nextNum',
            title: 'Patok Batas P$nextNum (GPS)',
            point: pos,
            time: 'Live GPS',
            description: 'Terukur via GPS Hardware',
            accuracy: '±${result.accuracy?.toStringAsFixed(1) ?? '2.0'}m',
          ));
        } else {
          // Update titik terakhir (P4 / Pn) dengan koordinat GPS nyata
          final int lastIdx = _points.length - 1;
          _points[lastIdx] = _points[lastIdx].copyWith(
            point: pos,
            accuracy: '±${result.accuracy?.toStringAsFixed(1) ?? '1.5'}m',
            description: 'Posisi Terkini GPS Lapangan',
          );
        }
      });

      _mapController.move(pos, 18.0);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    } else {
      // Tampilkan dialog panduan jika GPS belum aktif atau izin ditolak
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.location_disabled_rounded, color: AppTheme.dangerRed, size: 24),
              SizedBox(width: 8),
              Text('Lokasi GPS Perangkat', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            result.message,
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          actions: [
            if (result.status == LocationStatus.serviceDisabled)
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  LocationService.openLocationSettings();
                },
                child: const Text('Buka Pengaturan GPS'),
              ),
            if (result.status == LocationStatus.permissionDeniedForever)
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  LocationService.openAppSettings();
                },
                child: const Text('Buka Izin Aplikasi'),
              ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
              child: const Text('Tutup', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }

  /// Dialog Tambah Titik Koordinat Manual
  void _showAddPointDialog() {
    // Tidak diisi default koordinat — PPL harus mengukur/mengisi koordinat aktual di lapangan
    final latController = TextEditingController();
    final lonController = TextEditingController();
    final titleController = TextEditingController(text: 'Patok Batas P${_points.length + 1}');
    final descController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: AppTheme.lightGreen, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.add_location_alt_rounded, color: AppTheme.primaryGreen, size: 20),
            ),
            const SizedBox(width: 10),
            Text('Tambah Titik P${_points.length + 1}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Nama Patok / Posisi', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Nama patok wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: latController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  decoration: const InputDecoration(labelText: 'Latitude (-90 s/d 90)', border: OutlineInputBorder()),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Latitude wajib diisi';
                    final val = double.tryParse(v);
                    if (val == null || val < -90.0 || val > 90.0) return 'Latitude tidak valid (-90 s/d 90)';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: lonController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  decoration: const InputDecoration(labelText: 'Longitude (-180 s/d 180)', border: OutlineInputBorder()),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Longitude wajib diisi';
                    final val = double.tryParse(v);
                    if (val == null || val < -180.0 || val > 180.0) return 'Longitude tidak valid (-180 s/d 180)';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Keterangan Fisik Lahan', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final double lat = double.parse(latController.text.trim());
                final double lon = double.parse(lonController.text.trim());
                final int nextNum = _points.length + 1;

                setState(() {
                  _points.add(BoundaryPointItem(
                    code: 'P$nextNum',
                    title: titleController.text.trim(),
                    point: LatLng(lat, lon),
                    time: 'Manual',
                    description: descController.text.trim(),
                    accuracy: '±1.0m (Manual)',
                  ));
                });
                Navigator.pop(ctx);
                _mapController.move(LatLng(lat, lon), 17.6);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
            child: const Text('Simpan Titik', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Dialog Edit Titik Koordinat yang sudah ada
  void _showEditPointDialog(int index) {
    final item = _points[index];
    final latController = TextEditingController(text: item.point.latitude.toStringAsFixed(6));
    final lonController = TextEditingController(text: item.point.longitude.toStringAsFixed(6));
    final titleController = TextEditingController(text: item.title);
    final descController = TextEditingController(text: item.description);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Ubah Titik ${item.code}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Nama Patok', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Nama patok wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: latController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  decoration: const InputDecoration(labelText: 'Latitude', border: OutlineInputBorder()),
                  validator: (v) {
                    final val = double.tryParse(v ?? '');
                    if (val == null || val < -90.0 || val > 90.0) return 'Latitude tidak valid (-90 s/d 90)';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: lonController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  decoration: const InputDecoration(labelText: 'Longitude', border: OutlineInputBorder()),
                  validator: (v) {
                    final val = double.tryParse(v ?? '');
                    if (val == null || val < -180.0 || val > 180.0) return 'Longitude tidak valid (-180 s/d 180)';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Keterangan Patok', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final double lat = double.parse(latController.text.trim());
                final double lon = double.parse(lonController.text.trim());

                setState(() {
                  _points[index] = item.copyWith(
                    title: titleController.text.trim(),
                    point: LatLng(lat, lon),
                    description: descController.text.trim(),
                  );
                });
                Navigator.pop(ctx);
                _mapController.move(LatLng(lat, lon), 17.6);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
            child: const Text('Simpan Perubahan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Hapus Titik Batas
  void _deletePoint(int index) {
    if (_points.length <= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimal 3 titik patok diperlukan untuk membentuk poligon tertutup yang sah.'),
          backgroundColor: AppTheme.dangerRed,
        ),
      );
      return;
    }

    setState(() {
      _points.removeAt(index);
      // Renumber codes
      for (int i = 0; i < _points.length; i++) {
        _points[i] = _points[i].copyWith(code: 'P${i + 1}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final double areaM2 = _calculatedAreaM2;
    final double luasHaRdkk = _task.luasLahanM2 / 10000.0;
    final double areaHaUkur = areaM2 / 10000.0;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'E-PUPUK MOJOKERTO',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Survei',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined, color: AppTheme.textPrimary),
            onPressed: () {},
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16, left: 4),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.darkGreen,
              child: Text('AH', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breadcrumb Navigasi
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Row(
                children: [
                  const Icon(Icons.arrow_back, size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Peta & Lokasi Lahan (${_task.taskIdCode})',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Card Header: Target Pengukuran & Ringkasan Lahan
            _buildTargetHeaderCard(luasHaRdkk, areaHaUkur, areaM2),
            const SizedBox(height: 14),

            // Peta Interaktif Poligon & Batas Lahan
            _buildMeasurementMapArea(),
            const SizedBox(height: 12),

            // Toolbar Interaktif GPS & Tambah Titik
            _buildInteractiveGisToolbar(),
            const SizedBox(height: 14),

            // Notice Panduan Pengukuran PPL
            _buildMeasurementGuide(),
            const SizedBox(height: 14),

            // Daftar Titik Batas Valid P1..Pn dengan Aksi Edit/Delete
            _buildBoundaryPointsList(),
            const SizedBox(height: 14),

            // Banner Status Geometri Poligon & Keliling
            _buildPolygonReadyBanner(areaM2),
            const SizedBox(height: 20),

            // Tombol Aksi Bawah
            _buildActionButtons(areaM2),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetHeaderCard(double luasHaRdkk, double areaHaUkur, double areaM2) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PENGUKURAN BATAS LAHAN',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _task.namaPetani,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.lightGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_points.length} Patok WGS84',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Luas Usulan (e-RDKK)', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        '${luasHaRdkk.toStringAsFixed(2)} Ha',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      Text('(${_task.luasLahanM2.toInt()} m²)', style: const TextStyle(fontSize: 9, color: AppTheme.textMuted)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.lightGreen.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Luas Terukur (Geodetik)', style: TextStyle(fontSize: 10, color: AppTheme.darkGreen)),
                      const SizedBox(height: 2),
                      Text(
                        '${areaHaUkur.toStringAsFixed(2)} Ha',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                      ),
                      Text('(${areaM2.round()} m²)', style: const TextStyle(fontSize: 9, color: AppTheme.darkGreen)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementMapArea() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 330,
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: LatLng(_task.latitude, _task.longitude),
                  initialZoom: 17.6,
                  maxZoom: 19.5,
                  minZoom: 13.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: _isSatelliteLayer
                        ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.epupuk.mobile',
                    errorTileCallback: (tile, error, stackTrace) {
                      // Graceful handling jika tile offline atau status 400
                    },
                  ),

                  // Poligon Bidang Lahan Terukur (WGS-84)
                  if (_latLngPoints.length >= 3)
                    PolygonLayer(
                      polygons: [
                        Polygon(
                          points: _latLngPoints,
                          color: const Color(0x33078A61),
                          borderColor: AppTheme.primaryGreen,
                          borderStrokeWidth: 3.5,
                          isFilled: true,
                        ),
                      ],
                    ),

                  // Garis Hubung Poligon & Keliling
                  if (_latLngPoints.length >= 2)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: [..._latLngPoints, _latLngPoints.first],
                          color: AppTheme.primaryGreen,
                          strokeWidth: 3.5,
                        ),
                      ],
                    ),

                  // Marker Patok Batas P1..Pn
                  MarkerLayer(
                    markers: _points.map((pt) {
                      return Marker(
                        point: pt.point,
                        width: 44,
                        height: 44,
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: AppTheme.darkGreen,
                          child: Text(
                            pt.code,
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  // Marker Posisi Terkini GPS PPL jika tersedia
                  if (_deviceLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _deviceLocation!,
                          width: 80,
                          height: 50,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E3A8A),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'GPS PPL (±${_deviceAccuracy?.toStringAsFixed(1) ?? '2.0'}m)',
                                  style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const Icon(Icons.my_location, color: Color(0xFF2563EB), size: 22),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              // Tombol Floating Kanan Atas (Toggle Layer & Recenter)
              Positioned(
                top: 12,
                right: 12,
                child: Column(
                  children: [
                    _buildFloatingMapTool(
                      icon: _isSatelliteLayer ? Icons.layers : Icons.satellite_alt,
                      onTap: () => setState(() => _isSatelliteLayer = !_isSatelliteLayer),
                    ),
                    const SizedBox(height: 8),
                    _buildFloatingMapTool(
                      icon: Icons.crop_free,
                      onTap: () => _mapController.move(LatLng(_task.latitude, _task.longitude), 17.6),
                    ),
                  ],
                ),
              ),

              // Badge Geofencing & Status Lokasi Kiri Bawah
              Positioned(
                bottom: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.circle,
                        color: _isInsideLand ? const Color(0xFF22C55E) : const Color(0xFFF59E0B),
                        size: 8,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _isInsideLand ? 'Status: Di Dalam Batas Lahan' : 'Status: Di Luar Batas Lahan',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),

              // Badge Skala Kanan Bawah
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Text(
                    _isSatelliteLayer ? 'Citra Satelit Esri' : 'OpenStreetMap',
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingMapTool({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Icon(icon, size: 18, color: AppTheme.textPrimary),
      ),
    );
  }

  Widget _buildInteractiveGisToolbar() {
    return Row(
      children: [
        // Tombol Ambil Titik dari Live GPS
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isCapturingGps ? null : () => _captureDeviceGPS(addNewPoint: false),
            icon: _isCapturingGps
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.gps_fixed, size: 16, color: Colors.white),
            label: Text(
              _isCapturingGps ? 'Mencari GPS...' : 'Ambil Titik GPS',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Tombol Tambah Patok Manual
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _showAddPointDialog,
            icon: const Icon(Icons.add_location_alt_outlined, size: 16, color: AppTheme.primaryGreen),
            label: const Text(
              'Tambah Patok',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMeasurementGuide() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, size: 18, color: AppTheme.primaryGreen),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sumber Koordinat yang Dapat Digunakan',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                ),
                SizedBox(height: 4),
                Text(
                  '1. GPS perangkat: tekan "Ambil Titik GPS" di lapangan\n'
                  '2. Dokumen pengukuran resmi (jika mencantumkan titik koordinat)\n'
                  '3. Input manual dari alat ukur lapangan\n\n'
                  'Catat titik berurutan searah jarum jam. Jangan mengarang koordinat dari sertifikat yang tidak mencantumkan titik batas.',
                  style: TextStyle(fontSize: 10, color: Color(0xFF166534), height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoundaryPointsList() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.primaryGreen, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  const Text(
                    'Daftar Titik Batas Valid',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.lightGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_points.length} Titik Terverifikasi',
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Minimal 3 titik koordinat untuk membentuk bidang poligon tertutup yang sah.',
            style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 14),

          // Empty state jika belum ada titik
          if (_points.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Column(
                children: const [
                  Icon(Icons.add_location_alt_outlined, size: 36, color: Color(0xFFD97706)),
                  SizedBox(height: 8),
                  Text(
                    'Belum Ada Titik Batas',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Gunakan tombol "Tambah Patok" untuk memasukkan koordinat dari:\n'
                    '• Dokumen pengukuran resmi (jika mencantumkan koordinat)\n'
                    '• Pengukuran GPS langsung di lapangan\n'
                    '• Atau tekan "Ambil Titik GPS" untuk perekaman otomatis',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10.5, color: Color(0xFF92400E), height: 1.5),
                  ),
                ],
              ),
            ),

          // Render Item P1..Pn dengan tombol Edit dan Hapus
          ..._points.asMap().entries.map((entry) {
            final int idx = entry.key;
            final BoundaryPointItem pt = entry.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: AppTheme.darkGreen,
                      child: Text(
                        pt.code,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                pt.title,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.check_circle, size: 12, color: AppTheme.primaryGreen),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${pt.point.latitude.toStringAsFixed(6)}, ${pt.point.longitude.toStringAsFixed(6)}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${pt.time} • ${pt.description} (${pt.accuracy})',
                            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                    // Tombol Edit Titik
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF2563EB)),
                      onPressed: () => _showEditPointDialog(idx),
                      tooltip: 'Ubah Koordinat',
                    ),
                    // Tombol Hapus Titik
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.dangerRed),
                      onPressed: () => _deletePoint(idx),
                      tooltip: 'Hapus Titik',
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPolygonReadyBanner(double areaM2) {
    final validation = GeoCalcService.validatePolygon(_latLngPoints);
    final bool isValid = validation.isValid;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isValid ? AppTheme.lightGreen : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isValid ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.error_outline,
            size: 22,
            color: isValid ? AppTheme.primaryGreen : AppTheme.dangerRed,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isValid ? 'Poligon Siap Diperiksa (${GeoCalcService.formatM2(areaM2)})' : 'Geometri Poligon Perlu Perbaikan',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isValid ? AppTheme.primaryGreen : AppTheme.dangerRed,
                  ),
                ),
                Text(
                  isValid
                      ? 'Keliling: ${GeoCalcService.formatDistance(_calculatedPerimeterM)} • Geometri Tertutup WGS84'
                      : (validation.message ?? 'Poligon tidak valid'),
                  style: TextStyle(
                    fontSize: 10,
                    color: isValid ? const Color(0xFF166534) : const Color(0xFF991B1B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isValid ? '100% Valid' : 'Belum Valid',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isValid ? AppTheme.primaryGreen : AppTheme.dangerRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(double areaM2) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () {
              // Validasi geometri poligon sebelum navigasi
              final validation = GeoCalcService.validatePolygon(_latLngPoints);
              if (!validation.isValid) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(validation.message ?? 'Poligon batas lahan tidak valid.'),
                    backgroundColor: AppTheme.dangerRed,
                  ),
                );
                return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PPLHasilPengukuranScreen(
                    task: _task,
                    measuredAreaM2: areaM2,
                    polygonPoints: _latLngPoints,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
            label: const Text(
              'Lihat Hasil Pengukuran',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary, size: 16),
            label: const Text(
              'Kembali ke Peta Lahan',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}

