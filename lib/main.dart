import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

import 'package:proyecto_tutorias/features/login/views/welcome_view.dart';
import 'package:proyecto_tutorias/features/dashboard/views/home_menu_view.dart';

import 'package:proyecto_tutorias/routes/routes.dart';
import 'package:proyecto_tutorias/data/repositories/auth_repository.dart';

// ViewModels
import 'package:proyecto_tutorias/features/login/viewmodels/login_viewmodel.dart';
import 'package:proyecto_tutorias/features/operations/viewmodels/upload_evidence_viewmodel.dart';
import 'package:proyecto_tutorias/features/login/viewmodels/forgot_password_viewmodel.dart';
import 'package:proyecto_tutorias/features/splash/viewmodels/splash_viewmodel.dart';

// Views
import 'package:proyecto_tutorias/features/splash/views/splash_view.dart';

// Config
import 'package:proyecto_tutorias/core/config/app_scroll_behavior.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthRepository>(
          create: (_) => AuthRepository(firebaseAuth: FirebaseAuth.instance),
        ),
        ChangeNotifierProvider<LoginViewModel>(
          create: (context) => LoginViewModel(
            authRepository: context.read<AuthRepository>(),
          ),
        ),
        ChangeNotifierProvider<UploadEvidenceViewModel>(
          create: (context) => UploadEvidenceViewModel(
            authRepo: context.read<AuthRepository>(),
          ),
        ),
        ChangeNotifierProvider<ForgotPasswordViewModel>(
          create: (context) => ForgotPasswordViewModel(
            authRepository: context.read<AuthRepository>(),
          ),
        ),
        ChangeNotifierProvider<SplashViewModel>(
          create: (_) => SplashViewModel(),
        ),
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

      // --- NEW: Apply the custom scroll behavior ---
      scrollBehavior: AppScrollBehavior(),

      home: const SplashView(),
      routes: appRoutes,
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = context.watch<User?>();

    if (user == null) {
      return const WelcomeView();
    } else {
      return const HomeMenuView();
    }
  }
}
