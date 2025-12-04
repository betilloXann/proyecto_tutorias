// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

// --- Tus rutas ---
import 'package:proyecto_tutorias/routes/routes.dart';

// --- Tus vistas ---
import 'package:proyecto_tutorias/features/login/views/welcome_view.dart';
import 'package:proyecto_tutorias/features/dashboard/views/home_menu_view.dart';

// --- Tu Repositorio ---
import 'package:proyecto_tutorias/data/repositories/auth_repository.dart';

// --- TUS VIEWMODELS ---
import 'package:proyecto_tutorias/features/login/viewmodels/login_viewmodel.dart';
import 'package:proyecto_tutorias/features/dashboard/viewmodels/upload_evidence_viewmodel.dart';
// 1. IMPORTA EL NUEVO VIEWMODEL DE RECUPERACIÓN:
import 'package:proyecto_tutorias/features/login/viewmodels/forgot_password_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        // 1. Repositorio de autenticación (La base de todo)
        Provider<AuthRepository>(
          create: (_) => AuthRepository(firebaseAuth: FirebaseAuth.instance),
        ),

        // 2. Provider del LOGIN
        ChangeNotifierProvider<LoginViewModel>(
          create: (context) => LoginViewModel(
            authRepository: context.read<AuthRepository>(),
          ),
        ),

        // 3. Provider de SUBIR EVIDENCIA
        ChangeNotifierProvider<UploadEvidenceViewModel>(
          create: (context) => UploadEvidenceViewModel(
            authRepo: context.read<AuthRepository>(),
          ),
        ),

        // 4. Provider de RECUPERAR CONTRASEÑA (¡NUEVO!)
        ChangeNotifierProvider<ForgotPasswordViewModel>(
          create: (context) => ForgotPasswordViewModel(
            authRepository: context.read<AuthRepository>(),
          ),
        ),

        // 5. Stream del usuario actual (Para el AuthGate)
        StreamProvider<User?>(
          create: (context) => context.read<AuthRepository>().authStateChanges,
          initialData: null,
        ),
      ],
      child: const MyApp(),
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

      // 'AuthGate' decide la pantalla de inicio
      home: const AuthGate(),

      // Rutas para navegación
      routes: appRoutes,
    );
  }
}

// --- WIDGET 'AUTHGATE' ---
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // Escucha el Stream de 'User?'
    final User? user = context.watch<User?>();

    if (user == null) {
      return const WelcomeView();
    } else {
      return const HomeMenuView();
    }
  }
}