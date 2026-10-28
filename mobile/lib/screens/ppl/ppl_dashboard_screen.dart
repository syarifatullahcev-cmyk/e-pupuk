import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/user_model.dart';
import 'ppl_beranda_screen.dart';
import 'ppl_data_petani_screen.dart';
import 'ppl_daftar_tugas_screen.dart';
import 'ppl_aktivitas_screen.dart';
import 'ppl_profil_screen.dart';

class PPLDashboardScreen extends StatefulWidget {
  final UserModel user;

  const PPLDashboardScreen({super.key, required this.user});

  @override
  State<PPLDashboardScreen> createState() => _PPLDashboardScreenState();
}

class _PPLDashboardScreenState extends State<PPLDashboardScreen> {
  int _currentIndex = 0;

  void _onTabChange(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      PPLBerandaScreen(user: widget.user, onTabChange: _onTabChange),
      PPLDataPetaniScreen(user: widget.user),
      PPLDaftarTugasScreen(user: widget.user),
      PPLAktivitasScreen(user: widget.user),
      PPLProfilScreen(user: widget.user),
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: AppTheme.border, width: 0.8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_outlined, Icons.home, 'Beranda'),
                _buildNavItem(1, Icons.people_outline, Icons.people, 'Petani'),
                _buildNavItem(2, Icons.assignment_outlined, Icons.assignment, 'Survei'),
                _buildNavItem(3, Icons.history_outlined, Icons.history, 'Aktivitas'),
                _buildNavItem(4, Icons.person_outline, Icons.person, 'Profil'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData outlineIcon, IconData filledIcon, String label) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? AppTheme.primaryGreen : AppTheme.textMuted;

    return InkWell(
      onTap: () => _onTabChange(index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? filledIcon : outlineIcon,
              color: color,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
