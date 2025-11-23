import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/text_input_field.dart';
import 'register_view.dart'; // Importamos la siguiente pantalla

class StudentLookupView extends StatefulWidget {
  const StudentLookupView({super.key});

  @override
  State<StudentLookupView> createState() => _StudentLookupViewState();
}

class _StudentLookupViewState extends State<StudentLookupView> {
  final boletaCtrl = TextEditingController();
  bool _isLoading = false;

  void _searchStudent() async {
    final boleta = boletaCtrl.text.trim();
    if (boleta.isEmpty) return;

    setState(() => _isLoading = true);

    // --- SIMULACIÓN DE BACKEND (Firebase) ---
    // Aquí consultaríamos a Firestore: collections('usuarios').where('boleta', isEqualTo: boleta)
    await Future.delayed(const Duration(seconds: 1)); // Simulamos espera

    // CASO DE ÉXITO: Encontramos al alumno
    // Supongamos que la BD nos devolvió: { nombre: "Juan Pérez", estatus: "PRE_REGISTRO" }

    if (mounted) {
      setState(() => _isLoading = false);

      // Navegamos a la siguiente pantalla PASANDO LOS DATOS
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RegisterView(
            boleta: boleta,
            foundName: "Juan Pérez González", // Este dato vendría de la BD
          ),
        ),
      );
    }
    // ----------------------------------------
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