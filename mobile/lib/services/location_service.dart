import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

enum LocationStatus {
  ok,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  error,
}

class LocationResult {
  final bool isSuccess;
  final LatLng? position;
  final double? accuracy; // dalam meter
  final String message;
  final LocationStatus status;

  LocationResult({
    required this.isSuccess,
    this.position,
    this.accuracy,
    required this.message,
    required this.status,
  });
}

class LocationService {
  /// Mengambil posisi terkini perangkat menggunakan hardware GPS
  static Future<LocationResult> getCurrentLocation({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      // 1. Periksa apakah GPS / Location Service aktif di perangkat
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationResult(
          isSuccess: false,
          status: LocationStatus.serviceDisabled,
          message: 'Layanan lokasi (GPS) pada perangkat belum diaktifkan. Silakan aktifkan GPS.',
        );
      }

      // 2. Periksa status izin lokasi
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return LocationResult(
            isSuccess: false,
            status: LocationStatus.permissionDenied,
            message: 'Izin akses lokasi ditolak oleh pengguna.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return LocationResult(
          isSuccess: false,
          status: LocationStatus.permissionDeniedForever,
          message: 'Izin akses lokasi ditolak permanen. Buka Pengaturan Perangkat untuk memberikan izin lokasi ke e-Pupuk Mobile.',
        );
      }

      // 3. Ambil posisi GPS dengan akurasi tinggi dan timeout
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: timeout,
        ),
      );

      return LocationResult(
        isSuccess: true,
        status: LocationStatus.ok,
        position: LatLng(position.latitude, position.longitude),
        accuracy: position.accuracy,
        message: 'Lokasi GPS berhasil diperoleh (Akurasi: ±${position.accuracy.toStringAsFixed(1)}m).',
      );
    } on TimeoutException {
      return LocationResult(
        isSuccess: false,
        status: LocationStatus.timeout,
        message: 'Waktu tunggu pencarian sinyal GPS habis (Timeout). Pastikan Anda berada di ruang terbuka.',
      );
    } catch (e) {
      return LocationResult(
        isSuccess: false,
        status: LocationStatus.error,
        message: 'Gagal mengambil koordinat lokasi: $e',
      );
    }
  }

  /// Buka menu pengaturan lokasi perangkat
  static Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Buka menu pengaturan aplikasi (untuk izin denied forever)
  static Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }
}

