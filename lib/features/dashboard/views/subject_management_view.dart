import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/responsive_container.dart';
import '../../../data/models/professor_model.dart';
import '../viewmodels/subject_management_viewmodel.dart';
import '../../../data/models/subject_model.dart';
import '../../../theme/theme.dart';

class SubjectManagementView extends StatefulWidget {
  final String academy;
  const SubjectManagementView({super.key, required this.academy});

  @override
  State<SubjectManagementView> createState() => _SubjectManagementViewState();
}

class _SubjectManagementViewState extends State<SubjectManagementView> {
  late SubjectManagementViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = SubjectManagementViewModel(currentAcademy: widget.academy);
    _viewModel.loadSubjects(); // Asumiendo que este es el método que carga data
  }

  // Método para forzar la actualización de la data
  Future<void> _refreshData() async {
    await _viewModel.loadSubjects();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Materias de: ${widget.academy}"),
        ),
        body: ResponsiveContainer(
          child: Consumer<SubjectManagementViewModel>(
            builder: (context, vm, child) {
              if (vm.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (vm.errorMessage != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(vm.errorMessage!),
                      TextButton(onPressed: _refreshData, child: const Text("Reintentar"))
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _refreshData,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: vm.subjects.length,
                  physics: const AlwaysScrollableScrollPhysics(), // Necesario para RefreshIndicator
                  itemBuilder: (context, index) {
                    final subject = vm.subjects[index];
                    return _SubjectCard(subject: subject);
                  },
                ),
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddSubjectDialog(context, _viewModel),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  // Mantenemos el diálogo de añadir materia aquí por el contexto
  void _showAddSubjectDialog(BuildContext context, SubjectManagementViewModel vm) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Añadir Nueva Materia"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Nombre de la materia"),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              final success = await vm.addSubject(controller.text);
              if (success && dialogContext.mounted) {
                Navigator.pop(dialogContext);
                // Opcional: _refreshData(); // Si el vm no actualiza localmente
              }
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final SubjectModel subject;
  const _SubjectCard({required this.subject});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<SubjectManagementViewModel>();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subject.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.blueDark)),
            const Divider(height: 20),
            if (subject.professors.isEmpty)
              const Text("No hay profesores asignados.", style: TextStyle(color: Colors.grey))
            else
              ...subject.professors.map((prof) => ListTile(
                leading: const Icon(Icons.person, color: AppTheme.bluePrimary),
                title: Text(prof.name),
                subtitle: Text(prof.schedule),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey, size: 20),
                    onPressed: () => _showEditProfessorDialog(context, vm, subject.id, prof),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    onPressed: () => vm.removeProfessorFromSubject(subject.id, prof),
                  ),
                ]),
              )),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text("Añadir Profesor"),
                onPressed: () => _showAddProfessorDialog(context, vm, subject.id),
              ),
            )
          ],
        ),
      ),
    );
  }

  // Diálogos internos actualizados para asegurar cierre correcto
  void _showAddProfessorDialog(BuildContext context, SubjectManagementViewModel vm, String subjectId) {
    final nameController = TextEditingController();
    final scheduleController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Añadir Profesor"),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameController, decoration: const InputDecoration(labelText: "Nombre del profesor"), autofocus: true),
          const SizedBox(height: 10),
          TextField(controller: scheduleController, decoration: const InputDecoration(labelText: "Horario", hintText: "Ej. Lun-Mie 7-9")),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              final success = await vm.addProfessorToSubject(subjectId, nameController.text, scheduleController.text);
              if (success && dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  void _showEditProfessorDialog(BuildContext context, SubjectManagementViewModel vm, String subjectId, ProfessorModel oldProfessor) {
    final nameController = TextEditingController(text: oldProfessor.name);
    final scheduleController = TextEditingController(text: oldProfessor.schedule);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Editar Profesor"),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameController, decoration: const InputDecoration(labelText: "Nombre del profesor"), autofocus: true),
          const SizedBox(height: 10),
          TextField(controller: scheduleController, decoration: const InputDecoration(labelText: "Horario", hintText: "Ej. Lun-Mie 7-9")),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              final success = await vm.updateProfessorToSubject(subjectId, oldProfessor, nameController.text, scheduleController.text);
              if (success && dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
            },
            child: const Text("Actualizar"),
          ),
        ],
      ),
    );
  }
}