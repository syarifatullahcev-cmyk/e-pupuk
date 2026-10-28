import 'package:flutter/foundation.dart';

class ApiConfig {
  // Otomatis deteksi platform:
  // - Di Windows / macOS / Linux Desktop & Web: http://127.0.0.1:8000/api
  // - Di Android Emulator: http://10.0.2.2:8000/api
  // - Di HP Fisik Android: Bisa diatur IP lokal
  static String customBaseUrl = '';

  static String get baseUrl {
    if (customBaseUrl.isNotEmpty) {
      return customBaseUrl;
    }
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8000/api';
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
        return 'http://127.0.0.1:8000/api';
      default:
        return 'http://127.0.0.1:8000/api';
    }
  }

  // Autentikasi
  static String get loginUrl => '$baseUrl/auth/login';
  static String get registerUrl => '$baseUrl/auth/register';
  static String get profileUrl => '$baseUrl/auth/me';

  // Petani & Lahan
  static String get farmersUrl => '$baseUrl/farmers';
  static String farmerDetailUrl(int id) => '$baseUrl/farmers/$id';
  static String farmerLandsUrl(int farmerId) => '$baseUrl/lands?farmer_id=$farmerId';
  static String get farmerProfileUrl => '$baseUrl/farmers/me';
  static String get farmerMeUrl => '$baseUrl/farmers/me';
  static String get landsUrl => '$baseUrl/lands';
  static String landDetailUrl(int id) => '$baseUrl/lands/$id';
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
