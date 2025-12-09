import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/text_input_field.dart';
import '../../../data/repositories/auth_repository.dart';
import '../viewmodels/student_lookup_viewmodel.dart';
import 'register_view.dart';
import '../../../core/widgets/responsive_container.dart';

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
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    return ChangeNotifierProvider(
      create: (context) => StudentLookupViewModel(context.read<AuthRepository>()),
      child: Scaffold(
        backgroundColor: const Color(0xFFE6EEF8),
        resizeToAvoidBottomInset: false, // <--- OPTIMIZACIÓN TECLADO

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
            return ResponsiveContainer(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    /// IMAGEN PRINCIPAL
                    Image.asset(''
                        'assets/images/consulta.webp',
                      width: 260,
                      height: 240,
                    ),

                    /// TÍTULO
                    const Text(
                      "Validación de Estudiante",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2F5A93),
                      ),
                    ),

                    const SizedBox(height: 10),

                    /// SUBTÍTULO
                    const Text(
                      "Ingresa tu número de boleta para verificar que estás en el sistema.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 40),

                    /// INPUT
                    TextInputField(
                      label: "Número de Boleta",
                      controller: boletaCtrl,
                      icon: Icons.numbers,
                      keyboardType: TextInputType.number,
                    ),

                    /// ERROR
                    if (viewModel.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          viewModel.errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                    const SizedBox(height: 30),

                    /// BOTÓN PRINCIPAL
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: viewModel.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : PrimaryButton(
                        text: "Buscar y Continuar",
                        onPressed: () async {
                          final success = await viewModel.searchStudent(boletaCtrl.text);

                          if (success && context.mounted) {
                            final user = viewModel.foundUser;

                            if (user != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RegisterView(
                                    boleta: user.boleta,
                                    foundName: user.name,
                                    docId: user.id,
                                    email: user.email, // <-- THE FIX
                                  ),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
