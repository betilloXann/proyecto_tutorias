import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/responsive_container.dart'; // <--- IMPORTAR
import '../viewmodels/subject_list_viewmodel.dart';
import '../../../data/models/subject_model.dart';
import '../../../theme/theme.dart';

class SubjectListView extends StatelessWidget {
  final List<String> myAcademies;
  const SubjectListView({super.key, required this.myAcademies});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SubjectListViewModel(myAcademies: myAcademies),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Materias Disponibles"),
        ),
        // --- APLICANDO RESPONSIVE CONTAINER ---
        body: ResponsiveContainer(
          child: Consumer<SubjectListViewModel>(
            builder: (context, vm, child) {
              if (vm.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (vm.errorMessage != null) {
                return Center(child: Text(vm.errorMessage!));
              }
              if (vm.subjects.isEmpty) {
                return const Center(child: Text("No hay materias disponibles en este momento."));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: vm.subjects.length,
                itemBuilder: (context, index) {
                  final subject = vm.subjects[index];
                  return _SubjectCard(subject: subject);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final SubjectModel subject;
  const _SubjectCard({required this.subject});

  @override
  Widget build(BuildContext context) {
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
              const Text("No hay profesores asignados para esta materia.", style: TextStyle(color: Colors.grey))
            else
              ...subject.professors.map((prof) => ListTile(
                leading: const Icon(Icons.person_outline, color: AppTheme.bluePrimary),
                title: Text(prof.name),
                subtitle: Text(prof.schedule, style: const TextStyle(color: Colors.black54)),
              )),
          ],
        ),
      ),
    );
  }
}