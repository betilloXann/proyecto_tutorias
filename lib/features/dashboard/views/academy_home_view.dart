import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/professor_model.dart';
import '../../../data/models/subject_model.dart';
import '../../../theme/theme.dart';
import '../../../data/models/user_model.dart';
import '../viewmodels/academy_home_viewmodel.dart';
import '../viewmodels/home_menu_viewmodel.dart';
import 'subject_management_view.dart';
import 'student_detail_view.dart'; 

class AcademyHomeView extends StatefulWidget {
  const AcademyHomeView({super.key});

  @override
  State<AcademyHomeView> createState() => _AcademyHomeViewState();
}

class _AcademyHomeViewState extends State<AcademyHomeView> {
  
  // Convertimos la navegación en una función asíncrona segura
  Future<void> _navigateToDetail(UserModel student, AcademyViewModel vm) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => StudentDetailView(student: student)),
    );
    
    // Verificación de seguridad: Si la pantalla ya no existe, no hacemos nada.
    if (!mounted) return;
    
    // Si sigue activa, recargamos los datos.
    vm.loadInitialData();
  }

// Dentro de _AcademyHomeViewState

  void _navigateToSubjectManagement() {
    // Obtenemos el usuario actual del Provider
    final currentUser = context.read<HomeMenuViewModel>().currentUser;

    if (currentUser == null) return;

    // Lógica de seguridad:
    // Si el usuario tiene academias en la lista, usamos la primera.
    // Si la lista está vacía, usamos un valor por defecto o mostramos error.
    final String targetAcademy = currentUser.academies.isNotEmpty
        ? currentUser.academies.first
        : 'INFORMATICA'; // Fallback por seguridad

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubjectManagementView(academy: targetAcademy),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Escuchamos el usuario actual (solo lectura, no redibujamos todo por esto)
    final currentUser = context.select<HomeMenuViewModel, UserModel?>((vm) => vm.currentUser);
    final menuViewModel = context.read<HomeMenuViewModel>();

    // Prevención de error si el usuario aún no carga
    if (currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return ChangeNotifierProvider(
          // Pasamos la academia del usuario al ViewModel
    create: (_) => AcademyViewModel(myAcademies: currentUser.academies),
          child: Scaffold(
            backgroundColor: AppTheme.baseLight,
            appBar: AppBar(
              // Título dinámico: Si tiene 2, muestra "SISTEMAS, ROBOTICA"
              title: Text("ACADEMIA ${currentUser.academies.join(', ')}"),
          actions: [
            IconButton(
              icon: const Icon(Icons.ballot_outlined),
              tooltip: "Gestionar Materias",
              onPressed: _navigateToSubjectManagement,
            ),
            IconButton(
              icon: const Icon(Icons.logout), 
              onPressed: () async {
                final navigator = Navigator.of(context);
                await menuViewModel.logout();
                if (!mounted) return;
                navigator.pushNamedAndRemoveUntil('/login', (route) => false);
              }
            )
          ],
        ),
        body: Consumer<AcademyViewModel>(
          builder: (context, vm, child) {
            if (vm.isLoading) return const Center(child: CircularProgressIndicator());

            bool allListsEmpty = vm.pendingStudents.isEmpty &&
                                 vm.assignedStudents.isEmpty &&
                                 vm.accreditedStudents.isEmpty &&
                                 vm.notAccreditedStudents.isEmpty;

            if (allListsEmpty) {
              return RefreshIndicator(
                  onRefresh: vm.loadInitialData,
                  child: ListView(
                    children: [
                      const SizedBox(height: 100),
                      const Center(child: Text("No hay alumnos registrados en esta academia.")),
                      const SizedBox(height: 20),
                      Center(child: Text("Buscando en: ${vm.myAcademies.join(', ')}", style: const TextStyle(color: Colors.grey, fontSize: 12))),                    
                      ]
                  ),
              );
            }

            return RefreshIndicator(
              onRefresh: vm.loadInitialData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Pasamos 'vm' para poder recargar la lista al volver del detalle
                  _buildSection("PENDIENTES DE ASIGNACIÓN", vm.pendingStudents, (student) => _StudentCard(student: student), vm),
                  _buildSection("ALUMNOS CON CARGA ACADÉMICA", vm.assignedStudents, (student) => _AssignedStudentCard(student: student), vm),
                  _buildSection("HISTORIAL DE ACREDITADOS", vm.accreditedStudents, (student) => _FinishedStudentCard(student: student, isAccredited: true), vm),
                  _buildSection("HISTORIAL DE NO ACREDITADOS", vm.notAccreditedStudents, (student) => _FinishedStudentCard(student: student, isAccredited: false), vm),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<UserModel> students, Widget Function(UserModel) cardBuilder, AcademyViewModel vm) {
    if (students.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
          child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _getTitleColor(title))),
        ),
        ...students.map((student) => GestureDetector(
          onTap: () => _navigateToDetail(student, vm), 
          child: cardBuilder(student)
        )),
      ],
    );
  }

  Color _getTitleColor(String title) {
    if (title.contains("PENDIENTES")) return AppTheme.bluePrimary;
    if (title.contains("CARGA ACADÉMICA")) return Colors.green;
    return Colors.grey.shade700;
  }
}

// --- WIDGETS AUXILIARES (Sin cambios lógicos, solo visuales) ---

class _FinishedStudentCard extends StatelessWidget {
  final UserModel student;
  final bool isAccredited;

  const _FinishedStudentCard({required this.student, required this.isAccredited});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: isAccredited ? Colors.green.withAlpha(25) : Colors.red.withAlpha(25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: isAccredited ? Colors.green.withAlpha(100) : Colors.red.withAlpha(100))),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(children: [
          CircleAvatar(backgroundColor: isAccredited ? Colors.green : Colors.red, child: Icon(isAccredited ? Icons.check_circle_outline : Icons.cancel_outlined, color: Colors.white, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text("Boleta: ${student.boleta}", style: const TextStyle(color: Colors.grey)),
          ])),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ]),
      ),
    );
  }
}

class _AssignedStudentCard extends StatelessWidget {
  final UserModel student;
  const _AssignedStudentCard({required this.student});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: const Color(0xffe8f5e9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.green)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(children: [
          const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.check, color: Colors.white, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text("Boleta: ${student.boleta}", style: const TextStyle(color: Colors.grey)),
          ])),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ]),
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final UserModel student;
  const _StudentCard({required this.student});

  @override
  Widget build(BuildContext context) {
    // Usamos read porque solo necesitamos el VM para pasar al formulario, no escuchamos cambios aquí
    final vm = context.read<AcademyViewModel>(); 
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(children: [
            CircleAvatar(backgroundColor: AppTheme.blueSoft, child: Text(student.name[0], style: const TextStyle(fontWeight: FontWeight.bold))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text("Boleta: ${student.boleta}", style: const TextStyle(color: Colors.grey)),
            ])),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ]),
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
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
                builder: (_) => ChangeNotifierProvider.value(
                  value: vm,
                  child: _AssignmentForm(student: student),
                ),
              );
            },
          ),
        )
      ]),
    );
  }
}

class _AssignmentForm extends StatefulWidget {
  final UserModel student;
  const _AssignmentForm({required this.student});

  @override
  State<_AssignmentForm> createState() => _AssignmentFormState();
}

class _AssignmentFormState extends State<_AssignmentForm> {
  final _scheduleCtrl = TextEditingController();
  final _salonCtrl = TextEditingController();
  SubjectModel? _selectedSubject;
  ProfessorModel? _selectedProfessor;
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
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Todos los campos son obligatorios")));
      return;
    }

    setState(() => _isSaving = true);
    final success = await vm.assignSubject(
      studentId: widget.student.id,
      subjectName: _selectedSubject!.name,
      professorName: _selectedProfessor!.name,
      schedule: _scheduleCtrl.text,
      salon: _salonCtrl.text,
    );

    if (mounted && success){ 
      Navigator.pop(context);
    } else if(mounted) {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AcademyViewModel>();
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Asignar Materia y Pofesor", style: Theme.of(context).textTheme.titleLarge),
          Text("Alumno: ${widget.student.name}", style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          
          DropdownButtonFormField<SubjectModel>(
            key: ValueKey(_selectedSubject), 
            decoration: const InputDecoration(labelText: "Materia", border: OutlineInputBorder()),
            initialValue: _selectedSubject,
            items: vm.subjects.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
            onChanged: (val) => setState(() {
              _selectedSubject = val;
              _selectedProfessor = null;
              _scheduleCtrl.text = val?.professors.first.schedule ?? '';
            }),
          ),
          const SizedBox(height: 15),

          DropdownButtonFormField<ProfessorModel>(
            key: ValueKey(_selectedProfessor),
            decoration: const InputDecoration(labelText: "Profesor", border: OutlineInputBorder()),
            initialValue: _selectedProfessor,
            items: _selectedSubject?.professors.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
            onChanged: (val) => setState(() => _selectedProfessor = val),
          ),
          const SizedBox(height: 15),

          Row(children: [
            Expanded(child: TextField(controller: _scheduleCtrl, decoration: const InputDecoration(labelText: "Horario", hintText: "Ej. Lun-Mie 7-9", border: OutlineInputBorder()))),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: _salonCtrl, decoration: const InputDecoration(labelText: "Salón", hintText: "Ej. A-04", border: OutlineInputBorder()))),
          ]),
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