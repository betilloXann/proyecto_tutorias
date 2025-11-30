import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/theme.dart';
import '../../../data/models/user_model.dart';
import '../viewmodels/academy_home_viewmodel.dart';
// import '../viewmodels/home_menu_viewmodel.dart'; // Si necesitas logout

class AcademyHomeView extends StatelessWidget {
  const AcademyHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    // Inyectamos el VM específico de Academia
    return ChangeNotifierProvider(
      create: (_) => AcademyViewModel(),
      child: Scaffold(
        backgroundColor: AppTheme.baseLight,
        appBar: AppBar(
          title: const Text("Jefatura de Sistemas"), // Harcodeado por ahora
          automaticallyImplyLeading: false, // Quitamos flecha atrás si es root
          actions: [
            // Aquí podrías poner el botón de Logout igual que en StudentHomeView
            IconButton(icon: Icon(Icons.logout), onPressed: (){
              // Lógica de logout...
            })
          ],
        ),
        body: Consumer<AcademyViewModel>(
          builder: (context, vm, child) {
            if (vm.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (vm.pendingStudents.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, size: 80, color: Colors.green.withValues(alpha: 0.5)),
                    const SizedBox(height: 20),
                    const Text("¡Todo al día!", style: TextStyle(fontSize: 18, color: Colors.grey)),
                    const Text("No hay alumnos pendientes de asignación."),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vm.pendingStudents.length,
              itemBuilder: (context, index) {
                final student = vm.pendingStudents[index];
                return _StudentAssignmentCard(
                  student: student,
                  professors: vm.availableProfessors,
                  onAssign: (profName) {
                    vm.assignTutor(student.id, profName);
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Tutor asignado a ${student.name}"))
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// Tarjeta individual de Alumno
class _StudentAssignmentCard extends StatelessWidget {
  final UserModel student;
  final List<String> professors;
  final Function(String) onAssign;

  const _StudentAssignmentCard({
    required this.student,
    required this.professors,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                      Text(student.boleta, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8)
                  ),
                  child: const Text("Pendiente", style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                )
              ],
            ),
            const Divider(height: 30),
            const Text("Asignar Tutor:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            // Botón para abrir selección
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.basePure,
                    foregroundColor: AppTheme.bluePrimary,
                    elevation: 0,
                    side: const BorderSide(color: AppTheme.bluePrimary)
                ),
                child: const Text("Seleccionar Profesor"),
                onPressed: () {
                  _showSelectionDialog(context);
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showSelectionDialog(BuildContext context) {
    showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))
        ),
        builder: (context) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Asignar Tutor a ${student.name}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                ...professors.map((prof) => ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(prof),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.pop(context); // Cerrar modal
                    onAssign(prof); // Ejecutar asignación
                  },
                )),
              ],
            ),
          );
        }
    );
  }
}