import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/auth_repository.dart';
import '../viewmodels/home_menu_viewmodel.dart';

// Vistas
import 'student_home_view.dart';
import 'department_home_view.dart';
import 'academy_home_view.dart';

class HomeMenuView extends StatelessWidget {
  const HomeMenuView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => HomeMenuViewModel(context.read<AuthRepository>()),
      child: Scaffold(
        body: Consumer<HomeMenuViewModel>(
          builder: (context, viewModel, child) {

            // 1. CARGANDO
            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            // 2. ERROR O SIN SESIÓN
            if (viewModel.currentUser == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushReplacementNamed(context, '/login');
              });
              return const Center(child: Text("Error de sesión"));
            }

            final user = viewModel.currentUser!;

            // 3. SWITCH DE ROLES (Ajustado a tu UserModel)
            // Asegúrate que en Firebase el campo 'role' tenga estos valores exactos
            switch (user.role) {
              case 'student':
              // Pasamos el usuario como argumento para no volver a buscarlo
                return StudentHomeView(user: user);

              case 'tutorias':       // Depto. de Tutorías
              case 'gestion_escolar': // Gestión Escolar
              case 'admin':          // Admin general
                return const DepartmentHomeView();

              case 'jefe_academia':   // Jefes de Academia
                return const AcademyHomeView();

              default:
              // Si el rol está mal escrito en la BD o es nuevo
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 50, color: Colors.orange),
                      const SizedBox(height: 10),
                      Text("Rol no autorizado o desconocido: ${user.role}"),
                      TextButton(
                          onPressed: () => viewModel.logout(),
                          child: const Text("Cerrar Sesión")
                      )
                    ],
                  ),
                );
            }
          },
        ),
      ),
    );
  }
}