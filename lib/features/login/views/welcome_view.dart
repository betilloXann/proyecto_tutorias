import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/widgets/primary_button.dart';
// 1. Importamos
import '../../../core/widgets/responsive_container.dart';

class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      // 2. Usamos ResponsiveContainer.
      // Envuelve el Padding para que todo el contenido se centre en web.
      body: ResponsiveContainer(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // LOGO
              SvgPicture.asset(
                'assets/images/logo3.svg',
                width: 250,
                height: 250,
              ),

              const SizedBox(height: 20),

              // TITULO
              Text(
                "Bienvenido",
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // SUBTITULO
              Text(
                "Inicia sesión o activa tu cuenta para continuar",
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // BOTÓN PRINCIPAL
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  text: "Activar cuenta",
                  onPressed: () => Navigator.pushNamed(context, "/activation"),
                ),
              ),

              const SizedBox(height: 12),

              // TEXTO SECUNDARIO
              TextButton(
                onPressed: () => Navigator.pushNamed(context, "/login"),
                child: Text(
                  "Inicia sesión",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}