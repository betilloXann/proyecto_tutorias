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
  final curpCtrl = TextEditingController();

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
          leading: Consumer<StudentLookupViewModel>(
            builder: (context, vm, _) {
              return IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF2F5A93)),
                onPressed: () {
                  // Si estamos en paso de CURP, volvemos a búsqueda de boleta
                  if (vm.isBoletaVerified) {
                    vm.resetSearch();
                    curpCtrl.clear();
                  } else {
                    Navigator.of(context).pop();
                  }
                },
              );
            },
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
                    Text(
                      viewModel.isBoletaVerified
                          ? "Hola, ${viewModel.foundUser?.name}.\nPor favor verifica tu CURP para continuar."
                          : "Ingresa tu número de boleta para verificar que estás en el sistema.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // --- PASO 1: BOLETA (Visible si NO está verificado) ---
                    if (!viewModel.isBoletaVerified)
                    TextInputField(
                      label: "Número de Boleta",
                      controller: boletaCtrl,
                      icon: Icons.numbers,
                      keyboardType: TextInputType.number,
                    ),

                    // --- PASO 2: CURP (Visible solo SI está verificado) ---
                    if (viewModel.isBoletaVerified) ...[
                      const SizedBox(height: 10),
                      TextInputField(
                        label: "Ingresa tu CURP",
                        controller: curpCtrl,
                        icon: Icons.badge,
                        keyboardType: TextInputType.text,
                        textCapitalization: TextCapitalization.characters,
                      ),
                    ],

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
                    // BOTÓN DE ACCIÓN (Cambia según el paso)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: viewModel.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : PrimaryButton(
                        text: viewModel.isBoletaVerified
                            ? "Validar CURP y Continuar"
                            : "Buscar Estudiante",
                        onPressed: () async {
                          if (!viewModel.isBoletaVerified) {
                            // ACCIÓN 1: BUSCAR BOLETA
                            await viewModel.searchStudent(boletaCtrl.text);
                            // Si tiene éxito, la UI se actualiza sola gracias a isBoletaVerified
                          } else {
                            // ACCIÓN 2: VALIDAR CURP
                            final success = await viewModel.validateCurp(curpCtrl.text);

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
                                      email: user.email,
                                      curp: curpCtrl.text,
                                      // Nota: Considera pasar el CURP aquí también si RegisterView lo necesita
                                    ),
                                  ),
                                );
                              }
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
