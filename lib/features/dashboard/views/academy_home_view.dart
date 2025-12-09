import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/responsive_container.dart';
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

  void _navigateToSubjectManagement(BuildContext context) async {
    final currentUser = context.read<HomeMenuViewModel>().currentUser;
    if (currentUser == null) return;
    final String targetAcademy = currentUser.academies.isNotEmpty ? currentUser.academies.first : 'INFORMATICA';

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SubjectManagementView(academy: targetAcademy)),
    );

    if (context.mounted) {
      context.read<AcademyViewModel>().loadInitialData();
    }
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
        body: ResponsiveContainer(
          child: Consumer<AcademyViewModel>(
            builder: (context, vm, child) {
              if (vm.isLoading) return const Center(child: CircularProgressIndicator());

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Resumen de Alumnos", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.blueDark.withAlpha(200))),
                    const SizedBox(height: 16),

                    // --- 1. TARJETA RECTANGULAR ANCHA (PRE-REGISTRO) ---
                    // Se coloca FUERA del GridView para que ocupe todo el ancho.
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) =>
                            StudentListView(
                              title: 'Alumnos en Pre-registro',
                              students: vm.preRegisteredStudents,
                            )
                        ),
                      ),
                      // Usamos SizedBox para forzar una altura de rectángulo delgado
                      child: SizedBox(
                        height: 100,
                        child: _HoverableSummaryCard(
                          title: 'Pre-registro',
                          count: vm.preRegisteredStudents.length.toString(),
                          icon: Icons.person_add_alt_1_outlined,
                          color: Colors.purple.shade700,
                          isWide: true, // <-- Importante: activa el modo horizontal
                        ),
                      ),
                    ),

                    const SizedBox(height: 16), // Espacio entre el banner y el grid

                    // --- 2. GRID PARA LAS TARJETAS CUADRADAS RESTANTES ---
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
                          child: _HoverableSummaryCard(
                            title: 'Pendientes',
                            count: vm.pendingStudents.length.toString(),
                            icon: Icons.hourglass_top_outlined,
                            color: Colors.orange.shade700,
                          ),
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
                          child: _HoverableSummaryCard(
                            title: 'En Curso',
                            count: vm.assignedStudents.length.toString(),
                            icon: Icons.school_outlined,
                            color: AppTheme.bluePrimary,
                          ),
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
                          child: _HoverableSummaryCard(
                            title: 'Acreditados',
                            count: vm.accreditedStudents.length.toString(),
                            icon: Icons.check_circle_outlined,
                            color: Colors.green.shade700,
                          ),
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
                          child: _HoverableSummaryCard(
                            title: 'No Acreditados',
                            count: vm.notAccreditedStudents.length.toString(),
                            icon: Icons.cancel_outlined,
                            color: Colors.red.shade700,
                          ),
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
}

// --- WIDGET DE TARJETA MODIFICADO PARA SOPORTAR MODO ANCHO ---
class _HoverableSummaryCard extends StatefulWidget {
  final String title;
  final String count;
  final IconData icon;
  final Color color;
  final bool isWide; // Nuevo parámetro

  const _HoverableSummaryCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    this.isWide = false, // Por defecto es cuadrada (false)
  });

  @override
  State<_HoverableSummaryCard> createState() => _HoverableSummaryCardState();
}

class _HoverableSummaryCardState extends State<_HoverableSummaryCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // Corrección del 'scale' deprecado usando los 3 ejes explícitamente
    final transform = kIsWeb && _isHovered
        ? (Matrix4.identity()..scaleByDouble(1.05, 1.05, 1.05, 1.0))
        : Matrix4.identity();
    final duration = const Duration(milliseconds: 200);

    Widget cardContent;

    if (widget.isWide) {
      // --- Diseño Horizontal (Para el banner ancho) ---
      cardContent = Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(widget.icon, size: 40, color: widget.color),
          const SizedBox(width: 24), // Separación entre icono y texto
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(widget.count, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: widget.color)),
              Text(widget.title, style: TextStyle(fontSize: 16, color: widget.color.withValues(alpha: 0.8))),
            ],
          ),
        ],
      );
    } else {
      // --- Diseño Vertical Original (Para el grid) ---
      cardContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(widget.icon, size: 32, color: widget.color),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.count, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: widget.color)),
              Text(widget.title, style: TextStyle(color: widget.color.withValues(alpha: 0.8))),
            ],
          ),
        ],
      );
    }

    return MouseRegion(
      onEnter: (_) => { if (kIsWeb) setState(() => _isHovered = true) },
      onExit: (_) => { if (kIsWeb) setState(() => _isHovered = false) },
      child: AnimatedContainer(
        duration: duration,
        transform: transform,
        transformAlignment: FractionalOffset.center,
        child: Container(
          decoration: BoxDecoration(
              color: widget.color.withAlpha(_isHovered && kIsWeb ? 40 : 20),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: widget.color.withAlpha(50)),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withAlpha(_isHovered && kIsWeb ? 60 : 30),
                  blurRadius: _isHovered && kIsWeb ? 12 : 8,
                  offset: Offset(0, _isHovered && kIsWeb ? 6 : 4),
                )
              ]
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: cardContent, // Usamos el contenido determinado arriba
          ),
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
      if (_selectedSubject!.professors.length == 1) {
        _selectedProfessor = _selectedSubject!.professors.first;
        _scheduleCtrl.text = _selectedProfessor!.schedule;
      }
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
      Navigator.of(context).pop();
      Navigator.of(context).pop();
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
            initialValue: _selectedSubject,
            decoration: const InputDecoration(labelText: "Materia", border: OutlineInputBorder()),
            items: vm.availableSubjectsForStudent.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
            onChanged: (val) => setState(() {
              _selectedSubject = val;
              _selectedProfessor = null;
              _scheduleCtrl.clear();
              if (val != null && val.professors.length == 1) {
                _selectedProfessor = val.professors.first;
                _scheduleCtrl.text = _selectedProfessor!.schedule;
              }
            }),
          ),
          const SizedBox(height: 15),

          DropdownButtonFormField<ProfessorModel>(
            initialValue: _selectedProfessor,
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