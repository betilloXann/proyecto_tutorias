import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/responsive_container.dart';

class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,

        // Fondo degradado azul inspirado en la ilustración
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFEBF3FF), // azul muy claro
              Color(0xFFD6E7FF), // azul pastel
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        child: ResponsiveContainer(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 32,
                  horizontal: 24,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 18,
                      spreadRadius: 2,
                      offset: const Offset(0, 6),
                      color: Colors.black.withValues(alpha: 0.08),
                    )
                  ],
                ),

                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Ilustración o logo
                    SvgPicture.asset(
                      'assets/images/image5.svg',
                      width: 200,
                      height: 180,
                    ),

                    // Título moderno
                    Text(
                      "Bienvenido",
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2F5A93),
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    // Subtítulo más suave
                    Text(
                      "Inicia sesión o activa tu cuenta para continuar",
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.blueGrey.shade700,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 32),

                    // Botón principal estilo azul
                    SizedBox(
                      width: double.infinity,
                      child: PrimaryButton(
                        text: "Activar cuenta",
                        onPressed: () =>
                            Navigator.pushNamed(context, "/activation"),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Botón secundario como texto azul
                    TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, "/login"),
                      child: Text(
                        "Inicia sesión",
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
