import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/splash_viewmodel.dart';
import '../../login/views/welcome_view.dart';
import '../../dashboard/views/home_menu_view.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    // Ejecutamos la precarga apenas se construye el widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runPreload();
    });
  }

  Future<void> _runPreload() async {
    final viewModel = context.read<SplashViewModel>();
    
    // 1. Cargar recursos (imágenes)
    await viewModel.preloadResources(context);

    // 2. Revisar el estado de autenticación (AuthGate Logic)
    if (!mounted) return;
    
    final user = FirebaseAuth.instance.currentUser;

    // 3. Navegación con reemplazo (para no poder volver atrás al splash)
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => user == null ? const WelcomeView() : const HomeMenuView(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6EEF8), // Tu color de fondo base
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Tu logo
            Image.asset(
              'assets/images/app_icon.png',
              width: 140,
              height: 140,
            ),
            const SizedBox(height: 30),
            // Indicador de carga sutil
            const CircularProgressIndicator(
              color: Color(0xFF2F5A93),
            ),
          ],
        ),
      ),
    );
  }
}