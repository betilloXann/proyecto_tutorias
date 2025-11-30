// IMPORTS
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/text_input_field.dart';
import '../../../data/repositories/auth_repository.dart';
import '../viewmodels/student_lookup_viewmodel.dart';
import 'register_view.dart'; // <--- 1. DESCOMENTA ESTO

class StudentLookupView extends StatefulWidget {
  const StudentLookupView({super.key});

  @override
  State<StudentLookupView> createState() => _StudentLookupViewState();
}

class _StudentLookupViewState extends State<StudentLookupView> {
  final boletaCtrl = TextEditingController();

  @override
  void dispose() {
    boletaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => StudentLookupViewModel(context.read<AuthRepository>()),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF2F5A93)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Consumer<StudentLookupViewModel>(
          builder: (context, viewModel, child) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 40),
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
                    controller: boletaCtrl,
                    icon: Icons.numbers,
                    keyboardType: TextInputType.number,
                  ),

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
                        // A. Ejecutar búsqueda
                        final success = await viewModel.searchStudent(boletaCtrl.text);

                        // B. Verificar éxito y montaje
                        if (success && context.mounted) {
                          // C. OBTENER EL USUARIO QUE ENCONTRÓ EL VIEWMODEL
                          final user = viewModel.foundUser;

                          if (user != null) {
                            // D. NAVEGACIÓN MANUAL (PUSH) PARA PASAR DATOS
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RegisterView(
                                  // Pasamos los datos que RegisterView necesita
                                  boleta: user.boleta,
                                  foundName: user.name,
                                  docId: user.id,
                                ),
                              ),
                            );
                          }
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