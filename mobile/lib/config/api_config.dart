import 'package:flutter/foundation.dart';

class ApiConfig {
  // Otomatis deteksi platform:
  // - Di Browser Web / Chrome: http://127.0.0.1:8000/api
  // - Di Android Emulator: http://10.0.2.2:8000/api
  // - Di HP Fisik: Ganti dengan IP Wi-Fi laptop Anda (contoh: http://192.168.1.15:8000/api)
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api';
    }
    return 'http://10.253.129.6:8000/api';
  }

  // Autentikasi
  static String get loginUrl => '$baseUrl/auth/login';
  static String get registerUrl => '$baseUrl/auth/register';
  static String get profileUrl => '$baseUrl/auth/me';

  // Petani & Lahan
  static String get farmerProfileUrl => '$baseUrl/farmers/me';
  static String get farmerMeUrl => '$baseUrl/farmers/me';
  static String get landsUrl => '$baseUrl/lands';
  static String get fertilizersUrl => '$baseUrl/fertilizers';
  static String get commoditiesUrl => '$baseUrl/commodities';

  // Pengajuan Subsidi & Kuota
  static String get applicationsUrl => '$baseUrl/applications';
  static String get petaniStatsUrl => '$baseUrl/applications/stats/petani';
  static String reviseDocsUrl(int appId) =>
      '$baseUrl/applications/$appId/revise-docs';

  // Distribusi & QR Code
  static String get myDistributionsUrl => '$baseUrl/distributions/my';
  static String get scanQrUrl => '$baseUrl/distributions/scan-qr';
  static String get myScansUrl => '$baseUrl/distributions/scans/my';

  // PPL Lapangan & Survei
  static String get pplTasksUrl => '$baseUrl/ppl/assigned-tasks';
  static String pplStartSurveyUrl(int appId) =>
      '$baseUrl/ppl/applications/$appId/start-survey';
  static String pplSubmitSurveyUrl(int appId) =>
      '$baseUrl/ppl/applications/$appId/submit-survey';
}
