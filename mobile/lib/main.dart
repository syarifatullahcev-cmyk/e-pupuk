import 'package:flutter/material.dart';
import 'models/user_model.dart';
import 'screens/auth/login_screen.dart';
import 'screens/petani/petani_dashboard_screen.dart';
import 'screens/ppl/ppl_dashboard_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Cek apakah user sudah pernah login sebelumnya
  final currentUser = await AuthService.getCurrentUser();

  runApp(EPupukApp(initialUser: currentUser));
}

class EPupukApp extends StatelessWidget {
  final UserModel? initialUser;

  const EPupukApp({super.key, this.initialUser});

  Widget _getHome() {
    if (initialUser == null) return const LoginScreen();
    if (initialUser!.role == 'PPL') {
      return PPLDashboardScreen(user: initialUser!);
    }
    return PetaniDashboardScreen(user: initialUser!);
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF16A34A);

    return MaterialApp(
      title: 'e-Pupuk Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryGreen,
          primary: primaryGreen,
        ),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'sans-serif',
      ),
      home: _getHome(),
    );
  }
}
