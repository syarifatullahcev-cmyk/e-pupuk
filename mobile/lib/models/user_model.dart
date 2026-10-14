class UserModel {
  final int id;
  final String username;
  final String role;
  final String nama;
  final int? farmerId;
  final String? token;

  UserModel({
    required this.id,
    required this.username,
    required this.role,
    required this.nama,
    this.farmerId,
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, {String? token}) {
    return UserModel(
      id: json['user_id'] ?? json['id'] ?? 0,
      username: json['username'] ?? '',
      role: json['role'] ?? 'PETANI',
      nama: json['nama'] ?? json['username'] ?? '',
      farmerId: json['farmer_id'],
      token: token ?? json['access_token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'role': role,
      'nama': nama,
      'farmer_id': farmerId,
      'token': token,
    };
  }
}
