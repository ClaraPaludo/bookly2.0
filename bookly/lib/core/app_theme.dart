import 'package:flutter/material.dart';

class AppTheme {
  // Textos
  static const Color textLight = Color(0xFF7A8A99);

  static const Color subtitle = Color(0xFF5E7182);

  static const Color pageTitle = Color(0xFF12304A);

  // Fundo (papel azulado)
  static const Color background = Color(0xFFF4F8FC);

  // Azul principal (barra, botões, identidade)
  static const Color primary = Color(0xFF12304A);

  // Azul destaque (botões, detalhes)
  static const Color secondary = Color(0xFF4A90C2);

  // Estados
  static const Color success = Color(0xFF3FA66B);

  static const Color warning = Color(0xFFE9A23B);

  static const Color danger = Color(0xFFD9534F);

  // Cards
  static const Color card = Colors.white;

  // Bordas
  static const Color border = Color(0xFFD7E2EC);

  // Títulos
  static const Color title = Color(0xFF12304A);

  // Hoje / calendário
  static const Color today = Color(0xFF356A8A);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,

    scaffoldBackgroundColor: background,

    colorScheme: ColorScheme.fromSeed(seedColor: primary),

    appBarTheme: const AppBarTheme(
      backgroundColor: primary,
      foregroundColor: Colors.white,
    ),

    cardTheme: const CardThemeData(color: card, elevation: 2),
  );
}
