import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/theme.dart';
import '../../../data/models/user_model.dart';
import '../viewmodels/academy_home_viewmodel.dart';
import '../viewmodels/home_menu_viewmodel.dart';
import 'student_detail_view.dart'; // Import the new detail view

class AcademyHomeView extends StatelessWidget {
  const AcademyHomeView({super.key});

  // Helper method to navigate to the detail view
  void _navigateToDetail(BuildContext context, UserModel student) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentDetailView(student: student),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final menuViewModel = context.read<HomeMenuViewModel>();

    // The main ViewModel provider for this screen
    return ChangeNotifierProvider(
      create: (_) => AcademyViewModel(),
      child: Scaffold(
        backgroundColor: AppTheme.baseLight,
        appBar: AppBar(
          title: const Text("Gestión Académica"),
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
            if (vm.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (vm.pendingStudents.isEmpty && vm.assignedStudents.isEmpty) {
              return const Center(
                child: Text("No hay alumnos para mostrar.", style: TextStyle(color: Colors.grey)),
              );
            }

            return RefreshIndicator(
              onRefresh: vm.loadStudents,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // --- Section 1: Pending Students ---
                  if (vm.pendingStudents.isNotEmpty) ...[
                    const Text("PENDIENTES DE ASIGNACIÓN", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.bluePrimary)),
                    const SizedBox(height: 10),
                    ...vm.pendingStudents.map((student) {
                      return GestureDetector(
                        onTap: () => _navigateToDetail(context, student),
                        child: _StudentCard(student: student),
                      );
                    }),
                  ],

                  if (vm.pendingStudents.isNotEmpty && vm.assignedStudents.isNotEmpty) const SizedBox(height: 24),

                  // --- Section 2: Assigned Students ---
                  if (vm.assignedStudents.isNotEmpty) ...[
                    const Text("ALUMNOS CON CARGA ACADÉMICA", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green)),
                    const SizedBox(height: 10),
                    ...vm.assignedStudents.map((student) {
                      return GestureDetector(
                        onTap: () => _navigateToDetail(context, student),
                        child: _AssignedStudentCard(student: student),
                      );
                    }),
                  ]
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}


// --- Card for Assigned Students ---
class _AssignedStudentCard extends StatelessWidget {
  final UserModel student;
  const _AssignedStudentCard({required this.student});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: const Color(0xffe8f5e9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.green),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.check, color: Colors.white, size: 20)),
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
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

// --- Card for Pending Students ---
class _StudentCard extends StatelessWidget {
  final UserModel student;

  const _StudentCard({required this.student});

  @override
  Widget build(BuildContext context) {
    // Access the viewmodel from the context
    final vm = context.read<AcademyViewModel>();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // Make the top part tappable
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                CircleAvatar(backgroundColor: AppTheme.blueSoft, child: Text(student.name[0], style: const TextStyle(fontWeight: FontWeight.bold))),
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
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          // Assign button at the bottom
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
            child: TextButton.icon(
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text("Asignar Materia"),
              style: TextButton.styleFrom(foregroundColor: AppTheme.bluePrimary),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                  // Provide the existing VM to the modal sheet
                  builder: (_) => ChangeNotifierProvider.value(
                    value: vm,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                      child: _AssignmentForm(student: student),
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}


// --- Assignment Form ---
class _AssignmentForm extends StatefulWidget {
  final UserModel student;
  const _AssignmentForm({required this.student});

  @override
  State<_AssignmentForm> createState() => _AssignmentFormState();
}

class _AssignmentFormState extends State<_AssignmentForm> {
  final _scheduleCtrl = TextEditingController();
  final _salonCtrl = TextEditingController();
  String? _selectedSubject, _selectedProfessor;
  bool _isSaving = false;

  @override
  void dispose() {
    _scheduleCtrl.dispose();
    _salonCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    final vm = context.read<AcademyViewModel>();
    if (_selectedSubject == null || _selectedProfessor == null || _scheduleCtrl.text.isEmpty || _salonCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Todos los campos son obligatorios")));
      return;
    }

    setState(() => _isSaving = true);
    final success = await vm.assignSubject(
      studentId: widget.student.id,
      subjectName: _selectedSubject!,
      professorName: _selectedProfessor!,
      schedule: _scheduleCtrl.text,
      salon: _salonCtrl.text,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Materia asignada a ${widget.student.name}"), backgroundColor: Colors.green));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<AcademyViewModel>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Asignar Carga Académica", style: Theme.of(context).textTheme.titleLarge),
          Text("Alumno: ${widget.student.name}", style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: "Materia", border: OutlineInputBorder()),
            items: vm.availableSubjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (val) => setState(() => _selectedSubject = val),
          ),
          const SizedBox(height: 15),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: "Profesor", border: OutlineInputBorder()),
            items: vm.availableProfessors.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
            onChanged: (val) => setState(() => _selectedProfessor = val),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(child: TextField(controller: _scheduleCtrl, decoration: const InputDecoration(labelText: "Horario", hintText: "Ej. Lun-Mie 7-9", border: OutlineInputBorder()))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: _salonCtrl, decoration: const InputDecoration(labelText: "Salón", hintText: "Ej. A-04", border: OutlineInputBorder()))),
            ],
          ),
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: _isSaving
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.bluePrimary, foregroundColor: Colors.white),
                    onPressed: _submit,
                    child: const Text("Guardar Asignación"),
                  ),
          )
        ],
      ),
    );
  }
}
