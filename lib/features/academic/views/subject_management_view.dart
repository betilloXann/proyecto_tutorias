import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Widgets y Core
import '../../../core/widgets/responsive_container.dart';
import '../../../theme/theme.dart';

// Modelos
import '../../../data/models/professor_model.dart';
import '../../../data/models/subject_model.dart';
import '../../../data/models/user_model.dart';

// ViewModel
import '../viewmodels/subject_management_viewmodel.dart';

class SubjectManagementView extends StatefulWidget {
  final String academy;
  const SubjectManagementView({super.key, required this.academy});

  @override
  State<SubjectManagementView> createState() => _SubjectManagementViewState();
}

// 1. Agregamos 'with WidgetsBindingObserver' para detectar cuando la app vuelve al foco
class _SubjectManagementViewState extends State<SubjectManagementView> with WidgetsBindingObserver {
  late SubjectManagementViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    // 2. Registramos el observador
    WidgetsBinding.instance.addObserver(this);
    _viewModel = SubjectManagementViewModel(currentAcademy: widget.academy);
    _viewModel.loadSubjects();
  }

  @override
  void dispose() {
    // 3. Eliminamos el observador al salir
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 4. Lógica: Si minimizas la app y vuelves, se recargan las materias
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint("🔄 Volviendo a obtener los datos...");
      _viewModel.loadSubjects();
    }
  }

  // Método para forzar la actualización de la data
  Future<void> _refreshData() async {
    await _viewModel.loadSubjects();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      // Usamos PopScope para asegurar el comportamiento al salir (opcional, pero buena práctica)
      child: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) {
          // Nota: El "refresh" en la pantalla anterior (AcademyHomeView)
          // ya está garantizado por el 'await Navigator.push' que pusimos en el archivo anterior.
        },
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
                    physics: const AlwaysScrollableScrollPhysics(),
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
      ),
    );
  }

  // Diálogo añadir materia
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
                // No es necesario llamar _refreshData() aquí porque addSubject ya hace reload internamente
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

  void _showAddProfessorDialog(BuildContext context, SubjectManagementViewModel vm, String subjectId) async {
    // Aseguramos que la lista esté cargada
    await vm.loadAvailableProfessors();

    if (!context.mounted) return;

    // Si no hay profesores, avisa
    if (vm.availableProfessors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No hay profesores registrados. Crea uno primero.")));
      return;
    }

    UserModel? selectedProfessor;
    final scheduleController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder( // StatefulBuilder para actualizar el Dropdown
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Asignar Profesor a Materia"),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                // DROPDOWN DE PROFESORES
                DropdownButtonFormField<UserModel>(
                  decoration: const InputDecoration(labelText: "Selecciona Profesor"),
                  isExpanded: true,
                  items: vm.availableProfessors.map((prof) {
                    return DropdownMenuItem(
                      value: prof,
                      child: Text(prof.name, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => selectedProfessor = value),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: scheduleController,
                  decoration: const InputDecoration(labelText: "Horario y Salón", hintText: "Ej. L-M 7:00 - 1-05"),
                ),
              ]),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Cancelar")),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedProfessor == null || scheduleController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Selecciona profesor y horario")));
                      return;
                    }

                    final success = await vm.addProfessorToSubject(subjectId, selectedProfessor!, scheduleController.text);
                    if (success && dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: const Text("Asignar"),
                ),
              ],
            );
          }
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