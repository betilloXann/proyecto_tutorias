import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

// IMPORTS QUE NECESITAS (Ajusta las rutas si es necesario)
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/text_input_field.dart';
import '../../../data/repositories/auth_repository.dart';
import '../viewmodels/student_lookup_viewmodel.dart'; // Tu nuevo ViewModel
// import 'register_view.dart'; // Descomenta cuando tengas la vista de registro

// Volvemos a Stateful SOLO para manejar el controller del input (UI State)
class StudentLookupView extends StatefulWidget {
  const StudentLookupView({super.key});

  @override
  State<StudentLookupView> createState() => _StudentLookupViewState();
}

class _StudentLookupViewState extends State<StudentLookupView> {
  // El controlador pertenece a la UI, no al ViewModel
  final boletaCtrl = TextEditingController();

  @override
  void dispose() {
    boletaCtrl.dispose(); // Siempre hay que limpiar los controllers
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Inyectamos el ViewModel aquí
    return ChangeNotifierProvider(
      create: (context) => StudentLookupViewModel(
        context.read<AuthRepository>(),
      ),
      child: Scaffold(
        // backgroundColor: Colors.white, // O usa theme.colorScheme.surface
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF2F5A93)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        // 2. Usamos Consumer para reconstruir SOLO cuando el ViewModel cambie
        body: Consumer<StudentLookupViewModel>(
          builder: (context, viewModel, child) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  // Asegúrate que esta imagen existe o comenta la línea si da error
                  SvgPicture.asset("assets/images/logo.svg", height: 100),

                  const SizedBox(height: 30),
                  const Text(
                    "Validación de Estudiante",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2F5A93),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Ingresa tu número de boleta para verificar que estás en el sistema.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 40),

                  TextInputField(
                    label: "Número de Boleta",
                    controller: boletaCtrl, // Ahora sí existe
                    icon: Icons.numbers,
                    keyboardType: TextInputType.number,
                    // Opcional: Limpiar error al escribir
                    // onChanged: (_) => viewModel.clearError(),
                  ),

                  // Mostrar error desde el ViewModel
                  if (viewModel.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        viewModel.errorMessage!,
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: viewModel.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : PrimaryButton(
                      text: "Buscar y Continuar",
                      onPressed: () async {
                        // Llamamos a la lógica del ViewModel
                        final success = await viewModel.searchStudent(boletaCtrl.text);

                        // Verificamos si el widget sigue montado antes de navegar
                        if (success && context.mounted) {
                          // Navegación
                          // Navigator.pushNamed(context, '/register', arguments: ...);
                          // O tu navegación manual:
                          /*
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RegisterView(...),
                                  ),
                                );
                                */
                        }
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}