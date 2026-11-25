class ApiConfig {
  // Production URL backend di Vercel yang terhubung ke TiDB Cloud
  static const String productionUrl = 'https://e-pupuk.vercel.app/api';
  static String customBaseUrl = '';

  static String get baseUrl {
    if (customBaseUrl.isNotEmpty) {
      return customBaseUrl;
    }
    return productionUrl;
  }

  // Autentikasi
  static String get loginUrl => '$baseUrl/auth/login';
  static String get registerUrl => '$baseUrl/auth/register';
  static String get profileUrl => '$baseUrl/auth/me';

  // Petani & Lahan
  static String get farmersUrl => '$baseUrl/farmers';
  static String farmerDetailUrl(int id) => '$baseUrl/farmers/$id';
  static String farmerLandsUrl(int farmerId) =>
      '$baseUrl/lands?farmer_id=$farmerId';
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
  static String get notificationsUrl => '$baseUrl/notifications';
  static String notificationReadUrl(int id) =>
      '$baseUrl/notifications/$id/read';

  // PPL Lapangan & Survei
  static String get pplTasksUrl => '$baseUrl/ppl/assigned-tasks';
  static String pplStartSurveyUrl(int appId) =>
      '$baseUrl/ppl/applications/$appId/start-survey';
  static String pplSubmitSurveyUrl(int appId) =>
      '$baseUrl/ppl/applications/$appId/submit-survey';
}
