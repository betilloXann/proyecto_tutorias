import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/professor_model.dart';
import '../../../data/models/subject_model.dart';
import '../../../theme/theme.dart';
import '../../../data/models/user_model.dart';
import '../viewmodels/academy_home_viewmodel.dart';
import '../viewmodels/home_menu_viewmodel.dart';
import 'student_detail_view.dart';
import 'subject_management_view.dart';
import 'bulk_upload_view.dart'; 

class AcademyHomeView extends StatefulWidget {
  const AcademyHomeView({super.key});

  @override
  State<AcademyHomeView> createState() => _AcademyHomeViewState();
}

class _AcademyHomeViewState extends State<AcademyHomeView> {

  Future<void> _navigateToDetail(UserModel student, AcademyViewModel vm) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => StudentDetailView(student: student)),
    );
    if (!mounted) return;
    vm.loadInitialData();
  }

  void _navigateToSubjectManagement() {
    final currentUser = context.read<HomeMenuViewModel>().currentUser;
    if (currentUser == null) return;
    final String targetAcademy = currentUser.academies.isNotEmpty
        ? currentUser.academies.first
        : 'INFORMATICA';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubjectManagementView(academy: targetAcademy),
      ),
    );
  }

  void _navigateToBulkUpload() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BulkUploadView()),
    );
  }
  
  void _showAssignmentForm(BuildContext context, AcademyViewModel vm, UserModel student) {
    vm.filterSubjectsForStudent(student); // <-- FIX: Filter subjects before showing the form
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => ChangeNotifierProvider.value(
        value: vm,
        child: _AssignmentForm(student: student),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.select<HomeMenuViewModel, UserModel?>((vm) => vm.currentUser);
    final menuViewModel = context.read<HomeMenuViewModel>();

    if (currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return ChangeNotifierProvider(
      create: (_) => AcademyViewModel(myAcademies: currentUser.academies),
      child: Scaffold(
        backgroundColor: AppTheme.baseLight,
        appBar: AppBar(
          title: Text("ACADEMIA ${currentUser.academies.join(', ')}"),
          actions: [
             IconButton(
              icon: const Icon(Icons.upload_file_sharp),
              tooltip: "Carga Masiva de Alumnos",
              onPressed: _navigateToBulkUpload,
            ),
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
                child: ListView(children: const [SizedBox(height: 100), Center(child: Text("No hay alumnos registrados en esta academia."))]),
              );
            }

            return RefreshIndicator(
              onRefresh: vm.loadInitialData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSection("PENDIENTES DE ASIGNACIÓN", vm.pendingStudents, (student) => _StudentCard(student: student, onAssign: () => _showAssignmentForm(context, vm, student)), vm),
                  _buildSection("ALUMNOS CON CARGA ACADÉMICA", vm.assignedStudents, (student) => _AssignedStudentCard(student: student, onAssign: () => _showAssignmentForm(context, vm, student)), vm),
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
    if (title.contains("PRE-REGISTRADOS")) return Colors.purple;
    if (title.contains("PENDIENTES")) return AppTheme.bluePrimary;
    if (title.contains("CARGA ACADÉMICA")) return Colors.green;
    return Colors.grey.shade700;
  }
}

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
  final VoidCallback onAssign;
  const _AssignedStudentCard({required this.student, required this.onAssign});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: const Color(0xffe8f5e9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.green)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
          const Divider(height: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
            child: TextButton.icon(
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text("Asignar Otra Materia"),
              style: TextButton.styleFrom(foregroundColor: Colors.green.shade700),
              onPressed: onAssign,
            ),
          )
        ],
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final UserModel student;
  final VoidCallback onAssign;
  const _StudentCard({required this.student, required this.onAssign});

  @override
  Widget build(BuildContext context) {
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
            onPressed: onAssign,
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
  void initState() {
    super.initState();
    // Auto-select the subject if there's only one available
    final vm = context.read<AcademyViewModel>();
    if (vm.availableSubjectsForStudent.length == 1) {
      _selectedSubject = vm.availableSubjectsForStudent.first;
    }
  }

  @override
  void dispose() {
    _scheduleCtrl.dispose();
    _salonCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    final vm = context.read<AcademyViewModel>();
    if (_selectedSubject == null || _selectedProfessor == null || _salonCtrl.text.isEmpty) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Todos los campos son obligatorios")));
      return;
    }

    setState(() => _isSaving = true);
    final success = await vm.assignSubject(
      studentId: widget.student.id,
      subjectName: _selectedSubject!.name,
      professorName: _selectedProfessor!.name,
      schedule: _selectedProfessor!.schedule,
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
          Text("Asignar Materia y Profesor", style: Theme.of(context).textTheme.titleLarge),
          Text("Alumno: ${widget.student.name}", style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),

          // --- FIX: Use the filtered list of subjects ---
          DropdownButtonFormField<SubjectModel>(
            key: ValueKey(_selectedSubject),
            value: _selectedSubject,
            decoration: const InputDecoration(labelText: "Materia", border: OutlineInputBorder()),
            items: vm.availableSubjectsForStudent.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
            onChanged: (val) => setState(() {
              _selectedSubject = val;
              _selectedProfessor = null;
              _scheduleCtrl.clear();
            }),
          ),
          const SizedBox(height: 15),

          DropdownButtonFormField<ProfessorModel>(
            key: ValueKey(_selectedProfessor),
            decoration: const InputDecoration(labelText: "Profesor", border: OutlineInputBorder()),
            items: _selectedSubject?.professors.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
            onChanged: (val) => setState(() {
              _selectedProfessor = val;
              _scheduleCtrl.text = val?.schedule ?? '';
            }),
          ),
          const SizedBox(height: 15),

          Row(children: [
            Expanded(child: TextField(controller: _scheduleCtrl, readOnly: true, decoration: const InputDecoration(labelText: "Horario", border: OutlineInputBorder()))),
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
