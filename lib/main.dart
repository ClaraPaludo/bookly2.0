// Importa constantes do Flutter, como kIsWeb,
// que permite identificar se o app está rodando na Web.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'app.dart';

// Função principal do aplicativo.
// É o primeiro código executado quando o Bookly inicia.
Future<void> main() async {
  // Garante que o Flutter esteja completamente inicializado
  // antes de executar qualquer código (como abrir o banco de dados).
  WidgetsFlutterBinding.ensureInitialized();

  // Verifica se o aplicativo está sendo executado na Web.
  if (kIsWeb) {
    // Define a implementação do banco compatível com navegadores.
    databaseFactory = databaseFactoryFfiWeb;

    // Caso não seja Web, verifica se está rodando em Desktop.
  } else if (defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    // Inicializa o SQLite para Desktop.
    sqfliteFfiInit();

    // Define a implementação do banco para Desktop.
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const BooklyApp());
}
