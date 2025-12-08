import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/responsive_container.dart'; // <--- IMPORTAR
import '../../../data/models/professor_model.dart';
import '../../../data/models/subject_model.dart';
import '../../../data/models/user_model.dart';
import '../../../theme/theme.dart';
import '../viewmodels/academy_home_viewmodel.dart';
import '../viewmodels/home_menu_viewmodel.dart';
import 'student_list_view.dart';
import 'subject_management_view.dart';

class AcademyHomeView extends StatelessWidget {
  const AcademyHomeView({super.key});

  void _showAssignmentForm(BuildContext context, AcademyViewModel vm, UserModel student) {
    vm.filterSubjectsForStudent(student);
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

  void _navigateToSubjectManagement(BuildContext context) {
    final currentUser = context.read<HomeMenuViewModel>().currentUser;
    if (currentUser == null) return;
    final String targetAcademy = currentUser.academies.isNotEmpty ? currentUser.academies.first : 'INFORMATICA';

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SubjectManagementView(academy: targetAcademy)),
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
              icon: const Icon(Icons.ballot_outlined),
              tooltip: "Gestionar Materias",
              onPressed: () => _navigateToSubjectManagement(context),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                final navigator = Navigator.of(context);
                await menuViewModel.logout();
                if (!context.mounted) return;
                navigator.pushNamedAndRemoveUntil('/login', (route) => false);
              },
            )
          ],
        ),
        // --- APLICANDO RESPONSIVE CONTAINER ---
        body: ResponsiveContainer(
          child: Consumer<AcademyViewModel>(
            builder: (context, vm, child) {
              if (vm.isLoading) return const Center(child: CircularProgressIndicator());

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Resumen de Alumnos", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.blueDark.withValues(alpha: 0.8))),
                    const SizedBox(height: 16),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.3,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) =>
                                StudentListView(
                                  title: 'Pendientes de Asignación',
                                  students: vm.pendingStudents,
                                  onAssign: (student) => _showAssignmentForm(context, vm, student),
                                )
                            ),
                          ),
                          child: _buildSummaryCard('Pendientes', vm.pendingStudents.length.toString(), Icons.hourglass_top_outlined, Colors.orange.shade700),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) =>
                                StudentListView(
                                  title: 'Alumnos en Curso',
                                  students: vm.assignedStudents,
                                  onAssign: (student) => _showAssignmentForm(context, vm, student),
                                )
                            ),
                          ),
                          child: _buildSummaryCard('En Curso', vm.assignedStudents.length.toString(), Icons.school_outlined, AppTheme.bluePrimary),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) =>
                                StudentListView(
                                  title: 'Alumnos Acreditados',
                                  students: vm.accreditedStudents,
                                )
                            ),
                          ),
                          child: _buildSummaryCard('Acreditados', vm.accreditedStudents.length.toString(), Icons.check_circle_outlined, Colors.green.shade700),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) =>
                                StudentListView(
                                  title: 'Alumnos No Acreditados',
                                  students: vm.notAccreditedStudents,
                                )
                            ),
                          ),
                          child: _buildSummaryCard('No Acreditados', vm.notAccreditedStudents.length.toString(), Icons.cancel_outlined, Colors.red.shade700),
                        ),
                      ],
                    )
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String count, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08), // Corregido deprecation
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)) // Corregido deprecation
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 32, color: color),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(count, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
                Text(title, style: TextStyle(color: color.withValues(alpha: 0.8))),
              ],
            ),
          ],
        ),
      ),
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

          DropdownButtonFormField<SubjectModel>(
            key: ValueKey(_selectedSubject),
            initialValue: _selectedSubject, // Corregido deprecation
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