// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

// --- Tus rutas (para que 'routes: appRoutes' funcione) ---
import 'package:proyecto_tutorias/routes/routes.dart';

// --- Tus vistas (¡ESTAS SON LAS LÍNEAS CORREGIDAS!) ---
import 'package:proyecto_tutorias/features/login/views/welcome_view.dart';
import 'package:proyecto_tutorias/features/dashboard/views/home_menu_view.dart';

// --- Tu Repositorio (Asegúrate que la ruta sea correcta) ---
// (Probablemente 'lib/data/repositories/auth_repository.dart')
import 'package:proyecto_tutorias/data/repositories/auth_repository.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        // Proveedor para tu repositorio de autenticación
        Provider<AuthRepository>(
          create: (_) => AuthRepository(firebaseAuth: FirebaseAuth.instance),
        ),
        // Proveedor del Stream que nos dice si el usuario cambió
        StreamProvider<User?>(
          create: (context) => context.read<AuthRepository>().authStateChanges,
          initialData: null,
        ),
      ],
      child: const MyApp(), // Tu app normal
    ),
  );
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

      // 'AuthGate' ahora decide la pantalla de inicio
      home: const AuthGate(),

      // Tus rutas siguen funcionando para la navegación interna
      // (Ej. Navigator.pushNamed(context, '/login'))
      routes: appRoutes,
    );
  }
}

// --- --- --- --- --- --- --- --- --- --- --- ---
//       WIDGET 'AUTHGATE' (CORREGIDO)
// --- --- --- --- --- --- --- --- --- --- --- ---
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {

    // Escucha el Stream de 'User?' que proveímos
    final User? user = context.watch<User?>();

    if (user == null) {
      // No hay usuario, mostramos tu WelcomeView
      return const WelcomeView();
    } else {
      // Hay un usuario, mostramos tu HomeMenuView
      return const HomeMenuView();
    }
  }
}