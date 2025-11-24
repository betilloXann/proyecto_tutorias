import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart'; // Importante para acceder al repo

import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/text_input_field.dart';
import '../../../data/repositories/auth_repository.dart'; // Tu repositorio real
import 'register_view.dart';

class StudentLookupView extends StatefulWidget {
  const StudentLookupView({super.key});

  @override
  State<StudentLookupView> createState() => _StudentLookupViewState();
}

class _StudentLookupViewState extends State<StudentLookupView> {
  final boletaCtrl = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  void _searchStudent() async {
    final boleta = boletaCtrl.text.trim();
    if (boleta.isEmpty) {
      setState(() => _errorMessage = "Escribe una boleta");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. OBTENEMOS EL REPOSITORIO
      final authRepo = context.read<AuthRepository>();

      // 2. CONSULTAMOS A FIREBASE DE VERDAD
      final user = await authRepo.checkStudentStatus(boleta);

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (user == null) {
        // Caso: No existe la boleta en la BD
        setState(() => _errorMessage = "Boleta no encontrada en el pre-registro.");
      } else if (user.status != 'PRE_REGISTRO') {
        // Caso: Ya se registró antes
        setState(() => _errorMessage = "Esta cuenta ya fue activada. Intenta iniciar sesión.");
      } else {
        // 3. ÉXITO: Pasamos el nombre REAL que vino de Firebase
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RegisterView(
              boleta: user.boleta,      // Dato real de FB
              foundName: user.name,     // Dato real de FB ("Tu Nombre Real")
              docId: user.id,           // IMPORTANTE: Pasamos el ID del documento para actualizarlo luego
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Error de conexión: $e";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2F5A93)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            SvgPicture.asset("assets/images/logo.svg", height: 100),
            const SizedBox(height: 30),

            Text(
              "Validación de Estudiante",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2F5A93),
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

            // Muestra mensaje de error si existe
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : PrimaryButton(
                text: "Buscar y Continuar",
                onPressed: _searchStudent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}