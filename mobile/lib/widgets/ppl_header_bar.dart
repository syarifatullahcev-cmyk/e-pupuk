import 'package:flutter/material.dart';
import '../config/theme.dart';
import 'app_logo.dart';
import 'ppl_notifications_button.dart';

class PPLTopHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onProfileTap;
  final bool showBackButton;

  const PPLTopHeader({
    super.key,
    required this.title,
    this.onProfileTap,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showBackButton) ...[
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
            ],
            const AppLogo(size: 36, borderRadius: 10),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'E-PUPUK • KAB. MOJOKERTO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: AppTheme.darkGreen,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PPLNotificationsButton(),
            GestureDetector(
              onTap: onProfileTap,
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppTheme.darkGreen,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text(
                  'AH',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

PreferredSizeWidget buildPPLAppBar({
  required BuildContext context,
  required String title,
  bool showBackButton = false,
  VoidCallback? onProfileTap,
}) {
  return AppBar(
    backgroundColor: Colors.white,
    elevation: 0.5,
    titleSpacing: showBackButton ? 0 : 16,
    automaticallyImplyLeading: false,
    leading: showBackButton
        ? IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
            onPressed: () => Navigator.pop(context),
          )
        : null,
    title: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppLogo(size: 36, borderRadius: 10),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'E-PUPUK • KAB. MOJOKERTO',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: AppTheme.darkGreen,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ],
    ),
    actions: [
      const PPLNotificationsButton(),
      Padding(
        padding: const EdgeInsets.only(right: 16, left: 4),
        child: GestureDetector(
          onTap: onProfileTap,
          child: Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppTheme.darkGreen,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text(
              'AH',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    ],
  );
}
