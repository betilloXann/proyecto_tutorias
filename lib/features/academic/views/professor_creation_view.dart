import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/text_input_field.dart';

class ProfessorCreationView extends StatefulWidget {
  final String academy;
  const ProfessorCreationView({super.key, required this.academy});

  @override
  State<ProfessorCreationView> createState() => _ProfessorCreationViewState();
}

class _ProfessorCreationViewState extends State<ProfessorCreationView> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;

  void _createProfessor() async {
    if (_nameCtrl.text.isEmpty || _emailCtrl.text.isEmpty || _passCtrl.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Verifica los datos. Contraseña mín. 6 caracteres.")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authRepo = context.read<AuthRepository>();
      await authRepo.createProfessorUser(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
        name: _nameCtrl.text.trim(),
        academy: widget.academy,
      );

      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profesor creado exitosamente")));
        Navigator.pop(context); // Regresa a la lista
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registrar Nuevo Profesor")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextInputField(label: "Nombre Completo", controller: _nameCtrl, icon: Icons.person),
            const SizedBox(height: 16),
            TextInputField(label: "Correo Institucional", controller: _emailCtrl, icon: Icons.email, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 16),
            TextInputField(label: "Contraseña Temporal", controller: _passCtrl, icon: Icons.lock, obscureText: true, textInputAction: TextInputAction.done),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : SizedBox(width: double.infinity, height: 50, child: PrimaryButton(text: "Crear Profesor", onPressed: _createProfessor)),
          ],
        ),
      ),
    );
  }
}