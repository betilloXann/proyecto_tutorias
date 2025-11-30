import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/theme.dart';
import '../../../data/models/user_model.dart';
import '../viewmodels/academy_home_viewmodel.dart';
import '../viewmodels/home_menu_viewmodel.dart';

class AcademyHomeView extends StatelessWidget {
  const AcademyHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final menuViewModel = context.read<HomeMenuViewModel>();

    return ChangeNotifierProvider(
      create: (_) => AcademyViewModel(),
      child: Scaffold(
        backgroundColor: AppTheme.baseLight,
        appBar: AppBar(
          title: const Text("Asignación de Carga"),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(icon: const Icon(Icons.logout), onPressed: () async {
              await menuViewModel.logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            })
          ],
        ),
        body: Consumer<AcademyViewModel>(
          builder: (context, vm, child) {
            if (vm.isLoading) return const Center(child: CircularProgressIndicator());

            if (vm.pendingStudents.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, size: 80, color: Colors.green.withValues(alpha: 0.5)),
                    const SizedBox(height: 20),
                    const Text("Sin pendientes", style: TextStyle(fontSize: 18, color: Colors.grey)),
                    const Text("Todos los alumnos tienen carga académica."),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vm.pendingStudents.length,
              itemBuilder: (context, index) {
                final student = vm.pendingStudents[index];
                return _StudentCard(
                  student: student,
                  vm: vm, // Pasamos el VM para acceder a las listas
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// Tarjeta del Alumno
class _StudentCard extends StatelessWidget {
  final UserModel student;
  final AcademyViewModel vm;

  const _StudentCard({required this.student, required this.vm});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.blueSoft,
                  child: Text(student.name[0], style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("Boleta: ${student.boleta}", style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text("Asignar Materia"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.basePure,
                  foregroundColor: AppTheme.bluePrimary,
                  elevation: 0,
                  side: const BorderSide(color: AppTheme.bluePrimary),
                ),
                onPressed: () {
                  // Abrimos el Formulario
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true, // Importante para que el teclado no tape
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20))
                    ),
                    builder: (context) => Padding(
                      padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom // Ajuste teclado
                      ),
                      child: _AssignmentForm(student: student, vm: vm),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}

// --- EL FORMULARIO DE ASIGNACIÓN (Stateful para manejar sus inputs) ---
class _AssignmentForm extends StatefulWidget {
  final UserModel student;
  final AcademyViewModel vm;

  const _AssignmentForm({required this.student, required this.vm});

  @override
  State<_AssignmentForm> createState() => _AssignmentFormState();
}

class _AssignmentFormState extends State<_AssignmentForm> {
  final _scheduleCtrl = TextEditingController();
  final _salonCtrl = TextEditingController();

  String? _selectedSubject;
  String? _selectedProfessor;
  bool _isSaving = false;

  @override
  void dispose() {
    _scheduleCtrl.dispose();
    _salonCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_selectedSubject == null || _selectedProfessor == null || _scheduleCtrl.text.isEmpty || _salonCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Todos los campos son obligatorios")));
      return;
    }

    setState(() => _isSaving = true);

    // Llamamos al ViewModel
    final success = await widget.vm.assignSubject(
      studentId: widget.student.id,
      subjectName: _selectedSubject!,
      professorName: _selectedProfessor!,
      schedule: _scheduleCtrl.text,
      salon: _salonCtrl.text,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.pop(context); // Cerramos el modal
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Materia asignada a ${widget.student.name}"), backgroundColor: Colors.green)
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Asignar Carga Académica", style: Theme.of(context).textTheme.titleLarge),
          Text("Alumno: ${widget.student.name}", style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),

          // 1. Dropdown Materia
          DropdownButtonFormField<String>(
            initialValue: _selectedSubject,
            decoration: const InputDecoration(labelText: "Materia", border: OutlineInputBorder()),
            items: widget.vm.availableSubjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (val) => setState(() => _selectedSubject = val),
          ),
          const SizedBox(height: 15),

          // 2. Dropdown Profesor
          DropdownButtonFormField<String>(
            initialValue: _selectedProfessor,
            decoration: const InputDecoration(labelText: "Profesor", border: OutlineInputBorder()),
            items: widget.vm.availableProfessors.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
            onChanged: (val) => setState(() => _selectedProfessor = val),
          ),
          const SizedBox(height: 15),

          // 3. Horario y Salón (En fila)
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _scheduleCtrl,
                  decoration: const InputDecoration(
                      labelText: "Horario",
                      hintText: "Ej. Lun-Mie 7-9",
                      border: OutlineInputBorder()
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _salonCtrl,
                  decoration: const InputDecoration(
                      labelText: "Salón",
                      hintText: "Ej. A-04",
                      border: OutlineInputBorder()
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 25),

          // Botón Guardar
          SizedBox(
            width: double.infinity,
            height: 50,
            child: _isSaving
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.bluePrimary,
                foregroundColor: Colors.white,
              ),
              onPressed: _submit,
              child: const Text("Guardar Asignación"),
            ),
          )
        ],
      ),
    );
  }
}