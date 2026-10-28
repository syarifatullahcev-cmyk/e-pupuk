import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

class PolygonValidationResult {
  final bool isValid;
  final String? message;

  const PolygonValidationResult({required this.isValid, this.message});
}

class GeoCalcService {
  // WGS-84 Ellipsoid constants
  static const double earthRadius = 6378137.0; // semi-major axis a (meters)
  static const double earthMinorAxis = 6356752.314245; // semi-minor axis b (meters)
  static const double earthEccentricitySq = 0.00669437999014; // e^2 = 1 - (b^2 / a^2)

  /// 1. Menghitung luas poligon bola bumi (Geodesic Spherical Excess WGS-84) dalam m²
  /// Menggunakan algoritma spherical excess (Chamberlain-Duquette / Girard).
  static double calculateGeodesicArea(List<LatLng> points) {
    if (points.length < 3) return 0.0;

    double total = 0.0;
    final int n = points.length;
    for (int i = 0; i < n; i++) {
      final p1 = points[i];
      final p2 = points[(i + 1) % n];

      final double lat1 = p1.latitude * math.pi / 180.0;
      final double lat2 = p2.latitude * math.pi / 180.0;
      final double lon1 = p1.longitude * math.pi / 180.0;
      final double lon2 = p2.longitude * math.pi / 180.0;

      total += (lon2 - lon1) * (2.0 + math.sin(lat1) + math.sin(lat2));
    }

    final double area = total * earthRadius * earthRadius / 2.0;
    return area.abs();
  }

  /// 2. Menghitung luas bidang tanah menggunakan proyeksi elipsoid lokal WGS-84 (Local Ellipsoid Projected Area)
  /// Sangat akurat untuk bidang lahan pertanian skala desa/kecamatan (presisi sub-meter).
  static double calculateEllipsoidalArea(List<LatLng> points) {
    if (points.length < 3) return 0.0;

    // Hitung rata-rata lintang sebagai pusat proyeksi lokal
    double sumLat = 0.0;
    double sumLon = 0.0;
    for (final p in points) {
      sumLat += p.latitude;
      sumLon += p.longitude;
    }
    final double lat0Rad = (sumLat / points.length) * math.pi / 180.0;
    final double lon0Rad = (sumLon / points.length) * math.pi / 180.0;

    // Radius kurvatur meridian M dan prime vertical N pada lintang pusat
    final double sinLat0 = math.sin(lat0Rad);
    final double denom = 1.0 - (earthEccentricitySq * sinLat0 * sinLat0);
    final double sqrtDenom = math.sqrt(denom);
    final double M = earthRadius * (1.0 - earthEccentricitySq) / (denom * sqrtDenom);
    final double N = earthRadius / sqrtDenom;

    // Konversi setiap titik geodetik ke koordinat metrik lokal (x, y) dalam meter
    final List<math.Point<double>> metricPoints = [];
    for (final p in points) {
      final double latRad = p.latitude * math.pi / 180.0;
      final double lonRad = p.longitude * math.pi / 180.0;

      final double dLat = latRad - lat0Rad;
      final double dLon = lonRad - lon0Rad;

      final double x = N * math.cos(lat0Rad) * dLon;
      final double y = M * dLat;
      metricPoints.add(math.Point<double>(x, y));
    }

    // Shoelace formula pada bidang metrik datar yang terkalibrasi elipsoid
    double shoelace = 0.0;
    final int n = metricPoints.length;
    for (int i = 0; i < n; i++) {
      final p1 = metricPoints[i];
      final p2 = metricPoints[(i + 1) % n];
      shoelace += (p1.x * p2.y) - (p2.x * p1.y);
    }

    return (shoelace.abs() / 2.0);
  }

  /// 3. Menghitung jarak geodesik antara dua titik koordinat (Haversine Formula WGS-84) dalam meter
  static double calculateDistanceMeters(LatLng p1, LatLng p2) {
    final double lat1Rad = p1.latitude * math.pi / 180.0;
    final double lat2Rad = p2.latitude * math.pi / 180.0;
    final double deltaLat = (p2.latitude - p1.latitude) * math.pi / 180.0;
    final double deltaLon = (p2.longitude - p1.longitude) * math.pi / 180.0;

    final double a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.sin(deltaLon / 2) * math.sin(deltaLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  /// 4. Menghitung total keliling batas lahan (Perimeter) dalam meter
  static double calculatePerimeter(List<LatLng> points) {
    if (points.length < 2) return 0.0;
    double perimeter = 0.0;
    final int n = points.length;
    for (int i = 0; i < n; i++) {
      perimeter += calculateDistanceMeters(points[i], points[(i + 1) % n]);
    }
    return perimeter;
  }

  /// 5. Validasi geometri poligon batas lahan
  static PolygonValidationResult validatePolygon(List<LatLng> points) {
    if (points.length < 3) {
      return PolygonValidationResult(
        isValid: false,
        message: 'Poligon memerlukan minimal 3 titik sudut batas. Saat ini ada ${points.length} titik.',
      );
    }

    // Cek rentang nilai koordinat WGS-84
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      if (p.latitude < -90.0 || p.latitude > 90.0) {
        return PolygonValidationResult(
          isValid: false,
          message: 'Titik P${i + 1} memiliki Latitude tidak valid (${p.latitude}). Rentang sah: -90 s/d 90.',
        );
      }
      if (p.longitude < -180.0 || p.longitude > 180.0) {
        return PolygonValidationResult(
          isValid: false,
          message: 'Titik P${i + 1} memiliki Longitude tidak valid (${p.longitude}). Rentang sah: -180 s/d 180.',
        );
      }
    }

    // Cek titik duplikat berurutan
    for (int i = 0; i < points.length; i++) {
      final p1 = points[i];
      final p2 = points[(i + 1) % points.length];
      if (calculateDistanceMeters(p1, p2) < 0.1) {
        return PolygonValidationResult(
          isValid: false,
          message: 'Titik P${i + 1} identik atau terlalu dekat (< 10 cm) dengan titik berikutnya.',
        );
      }
    }

    // Cek apakah segmen berpotongan silang (Self-Intersecting Polygon)
    if (_hasSelfIntersection(points)) {
      return const PolygonValidationResult(
        isValid: false,
        message: 'Garis batas lahan saling berpotongan (Self-intersecting). Urutkan titik batas searah jarum jam.',
      );
    }

    return const PolygonValidationResult(isValid: true, message: null);
  }

  /// 6. Deteksi perpotongan garis batas (Self-intersection check)
  static bool _hasSelfIntersection(List<LatLng> points) {
    final int n = points.length;
    if (n < 4) return false;

    for (int i = 0; i < n; i++) {
      final a1 = points[i];
      final a2 = points[(i + 1) % n];

      for (int j = i + 1; j < n; j++) {
        // Jangan bandingkan segmen bertetangga yang berbagi titik ujung
        if ((i == 0 && j == n - 1) || (j == i + 1)) continue;

        final b1 = points[j];
        final b2 = points[(j + 1) % n];

        if (_linesIntersect(a1, a2, b1, b2)) {
          return true;
        }
      }
    }
    return false;
  }

  static bool _linesIntersect(LatLng p1, LatLng p2, LatLng p3, LatLng p4) {
    double ccw(LatLng a, LatLng b, LatLng c) {
      return (c.latitude - a.latitude) * (b.longitude - a.longitude) -
             (b.latitude - a.latitude) * (c.longitude - a.longitude);
    }

    final double d1 = ccw(p3, p4, p1);
    final double d2 = ccw(p3, p4, p2);
    final double d3 = ccw(p1, p2, p3);
    final double d4 = ccw(p1, p2, p4);

    return ((d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0)) &&
           ((d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0));
  }

  /// 7. Geofencing Ray-Casting: Memeriksa apakah suatu titik koordinat berada di dalam poligon lahan
  static bool isPointInPolygon(LatLng point, List<LatLng> polygon) {
    if (polygon.length < 3) return false;

    bool inside = false;
    final int n = polygon.length;
    double x = point.longitude;
    double y = point.latitude;

    for (int i = 0, j = n - 1; i < n; j = i++) {
      double xi = polygon[i].longitude, yi = polygon[i].latitude;
      double xj = polygon[j].longitude, yj = polygon[j].latitude;

      bool intersect = ((yi > y) != (yj > y)) &&
          (x < (xj - xi) * (y - yi) / (yj - yi) + xi);
      if (intersect) inside = !inside;
    }

    return inside;
  }

  /// 8. Format luas m² ke string dengan pemisah ribuan titik
  static String formatM2(double m2) {
    final int rounded = m2.round();
    final str = rounded.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write('.');
      }
    }
    return '${buffer.toString().split('').reversed.join()} m²';
  }

  /// 9. Format luas ke Hektare (Ha) dengan 2 desimal
  static String formatHa(double m2) {
    final double ha = m2 / 10000.0;
    return '${ha.toStringAsFixed(2).replaceAll('.', ',')} Ha';
  }

  /// 10. Format jarak dalam meter (m)
  static String formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(2)} km';
    }
    return '${meters.toStringAsFixed(1)} m';
  }
}
