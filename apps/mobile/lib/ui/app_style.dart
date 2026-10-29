import 'package:flutter/material.dart';

// Palette and shared pieces from the Doop frames.
const onboardInk = Color(0xFF1F3A30);
const onboardBg = Color(0xFFF0F5F2);
const onboardAmber = Color(0xFFF0A91E);
const onboardMuted = Color(0xFF5F7168);

/// The big dark call-to-action used at the foot of every onboarding screen.
class OnboardButton extends StatelessWidget {
  const OnboardButton({super.key, required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: onboardInk,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      ),
    );
  }
}

const onboardCard = Colors.white;
const _avatarColors = [
  (Color(0xFFF0A91E), Color(0xFF2A1D00)),
  (Color(0xFFD5E4DC), onboardInk),
  (Color(0xFFE8DAEF), Color(0xFF3A2447)),
  (Color(0xFF2F5547), Colors.white),
];

/// Rounded-square initial, coloured by position so a family reads at a glance.
class PersonAvatar extends StatelessWidget {
  const PersonAvatar({
    super.key,
    required this.name,
    this.colorIndex = 0,
    this.size = 44,
  });

  final String name;
  final int colorIndex;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _avatarColors[colorIndex % _avatarColors.length];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Text(
        name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase(),
        style: TextStyle(
          color: fg,
          fontSize: size * 0.4,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// Small caps section label ("LATER TODAY").
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: onboardMuted,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

ThemeData appTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: onboardInk,
    surface: onboardBg,
  ).copyWith(
    primary: onboardInk,
    secondaryContainer: onboardInk,
    onSecondaryContainer: Colors.white,
  );
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: onboardBg,
    appBarTheme: const AppBarTheme(
      backgroundColor: onboardBg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: onboardCard,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: onboardCard,
      selectedColor: onboardInk,
      showCheckmark: false,
      side: BorderSide.none,
      shape: const StadiumBorder(),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: onboardCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: onboardInk,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
  );
}
