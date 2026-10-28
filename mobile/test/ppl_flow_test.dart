import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:epupuk_mobile/services/geo_calc_service.dart';
import 'package:epupuk_mobile/models/ppl_task_model.dart';

void main() {
  group('E-PUPUK GIS & Geodesic Calculation Tests', () {
    // Poligon patok batas sawah Blok Kebondalem Mojosari
    final mojosariPoints = [
      const LatLng(-7.526210, 112.534015), // P1
      const LatLng(-7.526180, 112.534820), // P2
      const LatLng(-7.527010, 112.534850), // P3
      const LatLng(-7.527020, 112.534025), // P4
    ];

    test('1. Validasi poligon: Minimal 3 titik sudut untuk poligon sah', () {
      expect(GeoCalcService.calculateGeodesicArea([]), equals(0.0));
      expect(GeoCalcService.calculateGeodesicArea([const LatLng(-7.5, 112.5)]), equals(0.0));
      expect(GeoCalcService.calculateGeodesicArea([
        const LatLng(-7.5, 112.5),
        const LatLng(-7.5, 112.6),
      ]), equals(0.0));

      final valLess = GeoCalcService.validatePolygon([
        const LatLng(-7.5, 112.5),
        const LatLng(-7.5, 112.6),
      ]);
      expect(valLess.isValid, isFalse);
      expect(valLess.message, contains('minimal 3 titik'));
    });

    test('2. Validasi rentang koordinat: Latitude & Longitude tidak sah ditolak', () {
      final invalidLat = [
        const LatLng(-95.0, 112.5), // Lat invalid
        const LatLng(-7.5, 112.6),
        const LatLng(-7.6, 112.5),
      ];
      final valLat = GeoCalcService.validatePolygon(invalidLat);
      expect(valLat.isValid, isFalse);
      expect(valLat.message, contains('Latitude tidak valid'));

      final invalidLon = [
        const LatLng(-7.5, 195.0), // Lon invalid
        const LatLng(-7.5, 112.6),
        const LatLng(-7.6, 112.5),
      ];
      final valLon = GeoCalcService.validatePolygon(invalidLon);
      expect(valLon.isValid, isFalse);
      expect(valLon.message, contains('Longitude tidak valid'));
    });

    test('3. Validasi titik duplikat: Titik berturut-turut yang identik ditolak', () {
      final duplicatePoints = [
        const LatLng(-7.526210, 112.534015),
        const LatLng(-7.526210, 112.534015), // Duplikat
        const LatLng(-7.527010, 112.534850),
        const LatLng(-7.527020, 112.534025),
      ];
      final valDup = GeoCalcService.validatePolygon(duplicatePoints);
      expect(valDup.isValid, isFalse);
      expect(valDup.message, contains('identik atau terlalu dekat'));
    });

    test('4. Validasi Self-Intersection: Poligon menyilang (Bowtie) ditolak', () {
      // Titik bersilangan (P1 ke P3, P2 ke P4 menyilang)
      final bowtiePoints = [
        const LatLng(-7.526000, 112.534000), // P1 Kiri Atas
        const LatLng(-7.527000, 112.535000), // P2 Kanan Bawah
        const LatLng(-7.526000, 112.535000), // P3 Kanan Atas
        const LatLng(-7.527000, 112.534000), // P4 Kiri Bawah
      ];
      final valBowtie = GeoCalcService.validatePolygon(bowtiePoints);
      expect(valBowtie.isValid, isFalse);
      expect(valBowtie.message, contains('berpotongan'));
    });

    test('5. Validasi poligon sah Mojosari', () {
      final valValid = GeoCalcService.validatePolygon(mojosariPoints);
      expect(valValid.isValid, isTrue);
      expect(valValid.message, isNull);
    });

    test('6. Benchmark Luas Geodesik pada Lahan Uji 1 Hektare (100m x 100m)', () {
      // Bidang tanah bujur sangkar tepat 100m x 100m di sekitar ekuator
      // Pada latitude 0, 1 derajat lat ~ 111.319,5 m, 100m ~ 0.000898315 derajat
      const double dDeg = 100.0 / (GeoCalcService.earthRadius * (3.141592653589793 / 180.0));
      final test1HaPoints = [
        const LatLng(0.0, 0.0),
        const LatLng(0.0, dDeg),
        const LatLng(dDeg, dDeg),
        const LatLng(dDeg, 0.0),
      ];

      final area = GeoCalcService.calculateGeodesicArea(test1HaPoints);
      // Luas berada di kisaran 10.000 m² (toleransi ~1% elipsoidal vs bola bumi)
      expect(area, greaterThan(9900.0));
      expect(area, lessThan(10100.0));

      final ellipsoidalArea = GeoCalcService.calculateEllipsoidalArea(test1HaPoints);
      expect(ellipsoidalArea, greaterThan(9900.0));
      expect(ellipsoidalArea, lessThan(10100.0));
    });

    test('7. Uji dinamis: Mengubah koordinat titik benar-benar mengubah luas (Bukan Hardcoded)', () {
      final initialArea = GeoCalcService.calculateGeodesicArea(mojosariPoints);

      // Geser titik P2 lebih ke timur (+0.00100 derajat longitude ~ 110 meter)
      final modifiedPoints = [
        mojosariPoints[0],
        LatLng(mojosariPoints[1].latitude, mojosariPoints[1].longitude + 0.00100),
        mojosariPoints[2],
        mojosariPoints[3],
      ];

      final newArea = GeoCalcService.calculateGeodesicArea(modifiedPoints);
      expect(newArea, isNot(equals(initialArea)));
      expect(newArea, greaterThan(initialArea)); // Area harus bertambah karena batas diperlebar
    });

    test('8. Jarak Haversine dan Keliling Poligon (Perimeter)', () {
      final p1 = mojosariPoints[0];
      final p2 = mojosariPoints[1];

      final dist = GeoCalcService.calculateDistanceMeters(p1, p2);
      expect(dist, greaterThan(80.0));
      expect(dist, lessThan(100.0));

      final perimeter = GeoCalcService.calculatePerimeter(mojosariPoints);
      expect(perimeter, greaterThan(300.0)); // Keliling 4 sisi sawah Blok Kebondalem
      expect(perimeter, lessThan(450.0));
    });

    test('9. Geofencing Ray-Casting: Deteksi posisi di dalam vs di luar poligon', () {
      // Titik di tengah-tengah poligon sawah Mojosari
      final insidePoint = const LatLng(-7.526600, 112.534400);
      expect(GeoCalcService.isPointInPolygon(insidePoint, mojosariPoints), isTrue);

      // Titik jauh di luar lahan (misal di alun-alun Mojosari)
      final outsidePoint = const LatLng(-7.520000, 112.530000);
      expect(GeoCalcService.isPointInPolygon(outsidePoint, mojosariPoints), isFalse);
    });

    test('10. PPLTaskModel parsing dan mask NIK', () {
      final task = PPLTaskModel(
        id: 12,
        farmerId: 2,
        landId: 5,
        fertilizerId: 1,
        jumlahDiajukan: 240.0,
        status: 'DITUGASKAN_KE_PPL',
        namaPetani: 'Siti Aminah',
        nikPetani: '3516082104850002',
        kontakPetani: '0812-3456-78XX',
        namaPupuk: 'Urea Bersubsidi',
        lokasiLahan: 'Sawah Blok Timur Kebondalem',
        alamatLahan: 'Desa Tanjungrejo, Kec. Mojosari',
        luasLahanM2: 8000.0,
        latitude: -7.526412,
        longitude: 112.534218,
        komoditas: 'Padi Inpari 32',
        hasSurvey: false,
      );

      expect(task.initials, equals('SA'));
      expect(task.maskedNik, contains('******'));
      expect(task.taskIdCode, equals('SRV-2025-014'));
    });
  });
}
