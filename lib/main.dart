import 'package:flutter/material.dart';
import '../routes/routes.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sistema de Tutorías',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        scaffoldBackgroundColor: const Color(0xFFE6EEF8),
        useMaterial3: true,
      ),
      initialRoute: '/welcome',   // <--- Pantalla inicial
      routes: appRoutes,          // <--- Rutas definidas
    );
  }
}
