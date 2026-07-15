import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'pages/home_page.dart';

class BooklyApp extends StatelessWidget {
  const BooklyApp({super.key});

  // Método responsável por construir todo o aplicativo.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bookly',

      // Remove a faixa "DEBUG" da tela.
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomePage(),
    );
  }
}
