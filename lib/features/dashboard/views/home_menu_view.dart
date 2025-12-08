import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

//import '../../../data/models/user_model.dart';
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

            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (viewModel.currentUser == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
                      const SizedBox(height: 16),
                      const Text("Error de Sesión", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      const Text("No se pudieron cargar los datos de tu usuario. Por favor, intenta iniciar sesión de nuevo.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.logout),
                        label: const Text("Cerrar Sesión"),
                        onPressed: () async {
                          final navigator = Navigator.of(context);
                          await viewModel.logout();
                          if (!context.mounted) return;
                          navigator.pushNamedAndRemoveUntil('/login', (route) => false);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                      )
                    ],
                  ),
                ),
              );
            }

            final user = viewModel.currentUser!;

            switch (user.role) {
              case 'student':
                return StudentHomeView(user: user);

              // --- FIX: Pass the user object to DepartmentHomeView ---
              case 'tutorias':
              case 'admin':
                return DepartmentHomeView(user: user);

              case 'jefe_academia':
                return const AcademyHomeView();

              default:
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
