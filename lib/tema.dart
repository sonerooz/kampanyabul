import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// KampanyaBul görsel dili: gece mavisi zemin, zümrüt + amber vurgu, yumuşak cam kartlar.
/// (Turkcell Platinum'dan esinli ama kendi paletimiz: onların gümüş/neon-mint yerine zümrüt/amber.)
class R {
  static const zemin = Color(0xFF0F1626);
  static const zemin2 = Color(0xFF131C30);
  static const yuzey = Color(0xFF19243D);
  static const yuzey2 = Color(0xFF223152);
  static const cizgi = Color(0xFF2A3A5C);
  static const zumrut = Color(0xFF2DD4A7);
  static const zumrutKoyu = Color(0xFF14806A);
  static const amber = Color(0xFFFFB547);
  static const mercan = Color(0xFFFF6B6B);
  static const yazi = Color(0xFFF4F7FB);
  static const soluk = Color(0xFF9DB0CC);
  static const facebook = Color(0xFF1877F2);
}

/// Cam kart: sol üstten aydınlanan degrade + ince parlak kenar (gölge yok).
BoxDecoration camKutu({double yaricap = 20, Color? renk, bool vurgulu = false}) => BoxDecoration(
      borderRadius: BorderRadius.circular(yaricap),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: renk == null
            ? [R.yuzey2.withValues(alpha: 0.95), R.yuzey.withValues(alpha: 0.92)]
            : [renk, Color.lerp(renk, R.zemin, 0.55)!],
      ),
      border: Border.all(color: vurgulu ? R.zumrut.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.07)),
    );

/// Bulanık arka planlı yarı saydam katman (alt menü, üst düğmeler).
class Buzlu extends StatelessWidget {
  final Widget child;
  final double yaricap;
  final EdgeInsetsGeometry? padding;
  const Buzlu({super.key, required this.child, this.yaricap = 28, this.padding});

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(yaricap),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: R.yuzey.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(yaricap),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: child,
          ),
        ),
      );
}

ThemeData uygulamaTemasi() {
  const cs = ColorScheme.dark(
    primary: R.zumrut,
    onPrimary: R.zemin,
    primaryContainer: R.zumrutKoyu,
    onPrimaryContainer: Colors.white,
    secondary: R.amber,
    onSecondary: R.zemin,
    tertiary: R.amber,
    error: R.mercan,
    surface: R.zemin,
    onSurface: R.yazi,
    onSurfaceVariant: R.soluk,
    surfaceContainerLowest: R.zemin,
    surfaceContainerLow: R.zemin2,
    surfaceContainer: R.yuzey,
    surfaceContainerHigh: R.yuzey2,
    surfaceContainerHighest: R.yuzey2,
    outline: R.cizgi,
    outlineVariant: R.cizgi,
  );
  final tabanYazi = ThemeData(brightness: Brightness.dark).textTheme.apply(
        fontFamily: 'Jakarta',
        bodyColor: R.yazi,
        displayColor: R.yazi,
      );
  final hap = RoundedRectangleBorder(borderRadius: BorderRadius.circular(100));
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: cs,
    fontFamily: 'Jakarta',
    textTheme: tabanYazi,
    scaffoldBackgroundColor: R.zemin,
    canvasColor: R.zemin,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(fontFamily: 'Jakarta', fontSize: 22, fontWeight: FontWeight.w800, color: R.yazi),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: R.yuzey,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 52),
        shape: hap,
        textStyle: const TextStyle(fontFamily: 'Jakarta', fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 52),
        shape: hap,
        foregroundColor: R.yazi,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
        textStyle: const TextStyle(fontFamily: 'Jakarta', fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: R.zumrut, textStyle: const TextStyle(fontFamily: 'Jakarta', fontWeight: FontWeight.w700)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white.withValues(alpha: 0.06),
      selectedColor: R.zumrut,
      side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      shape: hap,
      labelStyle: const TextStyle(fontFamily: 'Jakarta', fontWeight: FontWeight.w600, fontSize: 13, color: R.yazi),
      secondaryLabelStyle: const TextStyle(fontFamily: 'Jakarta', fontWeight: FontWeight.w700, fontSize: 13, color: R.zemin),
      checkmarkColor: R.zemin,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.07),
      hintStyle: const TextStyle(color: R.soluk),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(100), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(100), borderSide: const BorderSide(color: R.zumrut)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: R.zemin2,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      dragHandleColor: R.cizgi,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: R.yuzey,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: R.yuzey2,
      contentTextStyle: const TextStyle(fontFamily: 'Jakarta', color: R.yazi),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? R.zemin : R.soluk),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? R.zumrut : R.yuzey2),
    ),
    dividerTheme: const DividerThemeData(color: R.cizgi, thickness: 1, space: 1),
    listTileTheme: const ListTileThemeData(iconColor: R.soluk),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: R.zumrut),
    popupMenuTheme: PopupMenuThemeData(color: R.yuzey2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
  );
}
