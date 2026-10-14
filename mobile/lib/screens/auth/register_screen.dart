import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  final _namaController = TextEditingController();
  final _nikController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _kontakController = TextEditingController();
  final _alamatController = TextEditingController();
  final _kelompokTaniController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _namaController.dispose();
    _nikController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _kontakController.dispose();
    _alamatController.dispose();
    _kelompokTaniController.dispose();
    super.dispose();
  }

  void _submitRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await AuthService.registerPetani(
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      nama: _namaController.text.trim(),
      nik: _nikController.text.trim(),
      kontak: _kontakController.text.trim(),
      alamat: _alamatController.text.trim(),
      kelompokTani: _kelompokTaniController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.green.shade700,
        ),
      );
      Navigator.pop(context); // Kembali ke halaman Login
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF16A34A);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Akun Petani'),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Registrasi Petani Baru',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Lengkapi data identitas Anda untuk mendapatkan akses subsidi pupuk resmi.',
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                ),
                const SizedBox(height: 24),

                // 1. Nama Lengkap
                TextFormField(
                  controller: _namaController,
                  decoration: _inputDecoration('Nama Lengkap Sesuai KTP', Icons.person_outline),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Nama lengkap wajib diisi' : null,
                ),
                const SizedBox(height: 16),

                // 2. NIK (Validasi 16 Digit)
                TextFormField(
                  controller: _nikController,
                  keyboardType: TextInputType.number,
                  maxLength: 16,
                  decoration: _inputDecoration('NIK (16 Digit Angka)', Icons.badge_outlined),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'NIK wajib diisi';
                    if (value.trim().length != 16) return 'NIK harus terdiri dari 16 digit angka';
                    if (!RegExp(r'^[0-9]+$').hasMatch(value.trim())) {
                      return 'NIK hanya boleh berupa angka';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // 3. Username
                TextFormField(
                  controller: _usernameController,
                  decoration: _inputDecoration('Username Akun', Icons.alternate_email),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Username wajib diisi' : null,
                ),
                const SizedBox(height: 16),

                // 4. Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration('Alamat Email Aktif', Icons.email_outlined),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Email wajib diisi';
                    if (!value.contains('@')) return 'Format email tidak valid';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 5. Password (Min 6 Karakter)
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: _inputDecoration('Kata Sandi (Min. 6 Karakter)', Icons.lock_outline).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Kata sandi wajib diisi';
                    if (value.length < 6) return 'Kata sandi minimal 6 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 6. Nomor Telepon / HP
                TextFormField(
                  controller: _kontakController,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecoration('Nomor WhatsApp / HP', Icons.phone_outlined),
                ),
                const SizedBox(height: 16),

                // 7. Kelompok Tani
                TextFormField(
                  controller: _kelompokTaniController,
                  decoration: _inputDecoration('Nama Kelompok Tani (Poktan)', Icons.groups_outlined),
                ),
                const SizedBox(height: 16),

                // 8. Alamat Domisili
                TextFormField(
                  controller: _alamatController,
                  maxLines: 2,
                  decoration: _inputDecoration('Alamat Domisili Lengkap', Icons.home_outlined),
                ),
                const SizedBox(height: 28),

                // Tombol Submit Register
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Daftar Sekarang',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(height: 16),

                // Link Kembali ke Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Sudah punya akun? ', style: TextStyle(color: Color(0xFF6B7280))),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        'Masuk di sini',
                        style: TextStyle(
                          color: primaryGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF16A34A)),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF16A34A), width: 2),
      ),
    );
  }
}
