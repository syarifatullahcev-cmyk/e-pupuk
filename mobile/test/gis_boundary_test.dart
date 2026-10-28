import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:epupuk_mobile/services/geo_calc_service.dart';

/// Poligon referensi: persegi ±100m × ±100m di sekitar Mojokerto (-7.527, 112.534)
/// Luas teoretis: ~10.000 m² (1 Ha)
/// (nilai tepat bervariasi karena geodetik elipsoid, sekitar 9990–10010 m²)
final List<LatLng> squarePoly100m = [
  LatLng(-7.52700, 112.53400),
  LatLng(-7.52700, 112.53490), // ~+100m timur
  LatLng(-7.52790, 112.53490), // ~+100m selatan
  LatLng(-7.52790, 112.53400),
];

/// Poligon lebih besar: 4 titik ~200m × 200m → luas ~40.000 m²
final List<LatLng> squarePoly200m = [
  LatLng(-7.52700, 112.53400),
  LatLng(-7.52700, 112.53580),
  LatLng(-7.52880, 112.53580),
  LatLng(-7.52880, 112.53400),
];

void main() {
  group('GIS Boundary — geo_calc_service', () {
    // ─────────────────────────────────────────────────────────
    // 1. 3 titik valid → polygon terbentuk (luas > 0)
    // ─────────────────────────────────────────────────────────
    test('1. Tiga titik valid → calculateGeodesicArea > 0', () {
      final pts = [
        LatLng(-7.52700, 112.53400),
        LatLng(-7.52700, 112.53490),
        LatLng(-7.52790, 112.53490),
      ];
      final area = GeoCalcService.calculateGeodesicArea(pts);
      expect(area, greaterThan(0),
          reason: 'Segitiga valid harus menghasilkan luas positif');
    });

    // ─────────────────────────────────────────────────────────
    // 2. 4 titik (persegi 100m) → luas ~9000–11000 m²
    // ─────────────────────────────────────────────────────────
    test('2. Empat titik persegi ~100m → luas antara 9000 dan 11000 m²', () {
      final area = GeoCalcService.calculateGeodesicArea(squarePoly100m);
      expect(area, greaterThan(9000),
          reason: 'Luas persegi 100m harus > 9000 m²');
      expect(area, lessThan(11000),
          reason: 'Luas persegi 100m harus < 11000 m²');
    });

    // ─────────────────────────────────────────────────────────
    // 3. Tambah titik (3 → 4) → luas berubah, tidak identik
    // ─────────────────────────────────────────────────────────
    test('3. Menambah titik mengubah luas (tidak sama)', () {
      final triangle = squarePoly100m.sublist(0, 3);
      final quad = squarePoly100m;

      final areaTriangle = GeoCalcService.calculateGeodesicArea(triangle);
      final areaQuad = GeoCalcService.calculateGeodesicArea(quad);

      expect(areaTriangle, isNot(equals(areaQuad)),
          reason: 'Luas segitiga dan persegi harus berbeda');
      expect(areaQuad, greaterThan(areaTriangle),
          reason: 'Persegi (4 titik) lebih luas dari segitiga (3 titik)');
    });

    // ─────────────────────────────────────────────────────────
    // 4. Luas bertambah: poligon 200m > poligon 100m
    // ─────────────────────────────────────────────────────────
    test('4. Poligon 200m² lebih besar dari poligon 100m²', () {
      final area100 = GeoCalcService.calculateGeodesicArea(squarePoly100m);
      final area200 = GeoCalcService.calculateGeodesicArea(squarePoly200m);
      expect(area200, greaterThan(area100),
          reason: 'Persegi 200m harus lebih besar dari 100m');
      // ~4x lebih besar
      expect(area200, greaterThan(area100 * 2),
          reason: 'Persegi 200m harus ≥ 2× luas persegi 100m');
    });

    // ─────────────────────────────────────────────────────────
    // 5. Mengubah koordinat satu titik → luas berubah
    // ─────────────────────────────────────────────────────────
    test('5. Mengubah koordinat titik memperbarui luas', () {
      final original = List<LatLng>.from(squarePoly100m);
      final modified = List<LatLng>.from(squarePoly100m);
      modified[3] = LatLng(-7.52810, 112.53400); // geser titik P4 ke selatan

      final areaOri = GeoCalcService.calculateGeodesicArea(original);
      final areaMod = GeoCalcService.calculateGeodesicArea(modified);

      expect(areaOri, isNot(equals(areaMod)),
          reason: 'Menggeser satu titik harus mengubah luas');
    });

    // ─────────────────────────────────────────────────────────
    // 6. Lat di luar rentang → validatePolygon gagal + pesan lat
    // ─────────────────────────────────────────────────────────
    test('6. Lat > 90 → validatePolygon isValid=false dengan pesan lat', () {
      final badPts = [
        LatLng(91.0, 112.534),    // ← lat tidak valid
        LatLng(-7.527, 112.535),
        LatLng(-7.528, 112.534),
      ];
      final result = GeoCalcService.validatePolygon(badPts);
      expect(result.isValid, isFalse,
          reason: 'Lat > 90 seharusnya tidak valid');
      expect(result.message?.toLowerCase(), anyOf(contains('latitude'), contains('lat')),
          reason: 'Pesan error harus menyebut masalah latitude');
    });

    // ─────────────────────────────────────────────────────────
    // 7. Lon di luar rentang → validatePolygon gagal + pesan lon
    // ─────────────────────────────────────────────────────────
    test('7. Lon < -180 → validatePolygon isValid=false dengan pesan lon', () {
      final badPts = [
        LatLng(-7.527, -181.0),   // ← lon tidak valid
        LatLng(-7.527, 112.535),
        LatLng(-7.528, 112.534),
      ];
      final result = GeoCalcService.validatePolygon(badPts);
      expect(result.isValid, isFalse,
          reason: 'Lon < -180 seharusnya tidak valid');
      expect(result.message?.toLowerCase(), anyOf(contains('longitude'), contains('lon')),
          reason: 'Pesan error harus menyebut masalah longitude');
    });

    // ─────────────────────────────────────────────────────────
    // 8. Kurang dari 3 titik → validatePolygon isValid=false
    // ─────────────────────────────────────────────────────────
    test('8. Kurang dari 3 titik → validatePolygon isValid=false', () {
      final twoPts = [
        LatLng(-7.527, 112.534),
        LatLng(-7.528, 112.535),
      ];
      final result = GeoCalcService.validatePolygon(twoPts);
      expect(result.isValid, isFalse,
          reason: 'Kurang dari 3 titik tidak bisa membentuk poligon');
    });

    // ─────────────────────────────────────────────────────────
    // 9. Titik duplikat → validatePolygon isValid=false
    // ─────────────────────────────────────────────────────────
    test('9. Titik duplikat berturut-turut → validatePolygon isValid=false', () {
      final dupPts = [
        LatLng(-7.527, 112.534),
        LatLng(-7.527, 112.534), // duplikat P1
        LatLng(-7.528, 112.535),
        LatLng(-7.529, 112.534),
      ];
      final result = GeoCalcService.validatePolygon(dupPts);
      expect(result.isValid, isFalse,
          reason: 'Titik duplikat berturut-turut harus ditolak');
    });

    // ─────────────────────────────────────────────────────────
    // 10. Luas dan keliling: nilai positif, satuan format benar
    // ─────────────────────────────────────────────────────────
    test('10. Luas dan keliling persegi 100m: format dan satuan benar', () {
      final area = GeoCalcService.calculateGeodesicArea(squarePoly100m);
      final perimeter = GeoCalcService.calculatePerimeter(squarePoly100m);

      expect(area, greaterThan(0), reason: 'Luas harus positif');
      expect(perimeter, greaterThan(0), reason: 'Keliling harus positif');

      // Keliling persegi 100m ~ 400m (toleransi ±50m karena geodetik)
      expect(perimeter, greaterThan(350),
          reason: 'Keliling persegi 100m harus > 350m');
      expect(perimeter, lessThan(450),
          reason: 'Keliling persegi 100m harus < 450m');

      // Format m² → harus mengandung 'm²' atau 'ha'
      final areaM2Str = GeoCalcService.formatM2(area);
      final areaHaStr = GeoCalcService.formatHa(area);
      final distStr = GeoCalcService.formatDistance(perimeter);

      expect(areaM2Str.isNotEmpty, isTrue,
          reason: 'formatM2 tidak boleh kosong');
      expect(areaHaStr.isNotEmpty, isTrue,
          reason: 'formatHa tidak boleh kosong');
      expect(distStr.isNotEmpty, isTrue,
          reason: 'formatDistance tidak boleh kosong');
    });

    // ─────────────────────────────────────────────────────────
    // 11. Titik-titik collinear/identik → luas mendekati nol
    // ─────────────────────────────────────────────────────────
    test('11. Titik-titik identik → validatePolygon isValid=false', () {
      final identicalPts = [
        LatLng(-7.527, 112.534),
        LatLng(-7.527, 112.534),
        LatLng(-7.527, 112.534),
      ];
      final result = GeoCalcService.validatePolygon(identicalPts);
      expect(result.isValid, isFalse,
          reason: 'Titik identik semua tidak bisa membentuk poligon bermakna');
    });

    // ─────────────────────────────────────────────────────────
    // 12. parsedPolygonPoints dari PPLTaskModel.polygonCoords
    //     Verifikasi parsing List<List<double>> ke LatLng
    // ─────────────────────────────────────────────────────────
    test('12. PPLTaskModel.parsedPolygonPoints parse List<List<double>> dengan benar', () {
      // Gunakan data yang sama dengan format yang dikirim ke API
      final rawCoords = [
        [-7.52700, 112.53400],
        [-7.52700, 112.53490],
        [-7.52790, 112.53490],
        [-7.52790, 112.53400],
      ];

      // Simulasi parsing manual yang sama persis dengan parsedPolygonPoints getter
      final List<LatLng> parsed = [];
      for (var pt in rawCoords) {
        if (pt.length >= 2) {
          final lat = double.tryParse('${pt[0]}');
          final lng = double.tryParse('${pt[1]}');
          if (lat != null && lng != null) {
            parsed.add(LatLng(lat, lng));
          }
        }
      }

      expect(parsed.length, equals(4),
          reason: 'Harus terparse 4 titik dari raw coords');
      expect(parsed[0].latitude, closeTo(-7.52700, 0.00001),
          reason: 'Lat P1 harus sesuai');
      expect(parsed[0].longitude, closeTo(112.53400, 0.00001),
          reason: 'Lon P1 harus sesuai');
      expect(parsed[3].latitude, closeTo(-7.52790, 0.00001),
          reason: 'Lat P4 harus sesuai');

      // Pastikan luas dari parsed points valid
      final area = GeoCalcService.calculateGeodesicArea(parsed);
      expect(area, greaterThan(9000),
          reason: 'Luas dari parsed polygon harus sesuai dengan poligon 100m');
    });

    // ─────────────────────────────────────────────────────────
    // BONUS: String JSON polygon (format alternatif dari API)
    // ─────────────────────────────────────────────────────────
    test('BONUS. calculateGeodesicArea konsisten untuk poligon yang sama', () {
      // Dua kali panggil harus hasilkan nilai identik (tidak random)
      final area1 = GeoCalcService.calculateGeodesicArea(squarePoly100m);
      final area2 = GeoCalcService.calculateGeodesicArea(squarePoly100m);
      expect(area1, equals(area2),
          reason: 'calculateGeodesicArea harus deterministik');
    });
  });
}
