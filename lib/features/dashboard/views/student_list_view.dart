import 'package:flutter/material.dart';
import '../../../data/models/user_model.dart';
import '../../../theme/theme.dart';
import 'package:collection/collection.dart'; // We need this for the groupBy function
import 'student_detail_view.dart';

class StudentListView extends StatefulWidget {
  final String title;
  final List<UserModel> students;

  const StudentListView({super.key, required this.title, required this.students});

  @override
  State<StudentListView> createState() => _StudentListViewState();
}

class _StudentListViewState extends State<StudentListView> {
  // The final structure: {academy: {subject: [students]}}
  late final Map<String, Map<String, List<UserModel>>> _groupedStudents;

  @override
  void initState() {
    super.initState();
    _groupAndSortStudents();
  }

  void _groupAndSortStudents() {
    // 1. Group by the first academy
    final groupedByAcademy = groupBy(widget.students, (student) => student.academies.firstOrNull ?? 'Sin Academia');

    _groupedStudents = {};

    // 2. For each academy, group by the first subject
    groupedByAcademy.forEach((academy, studentsInAcademy) {
      final groupedBySubject = groupBy(studentsInAcademy, (student) => student.subjectsToTake.firstOrNull ?? 'Sin Materia Asignada');
      
      // 3. For each subject, sort the students alphabetically
      groupedBySubject.forEach((subject, studentsInSubject) {
        studentsInSubject.sort((a, b) => a.name.compareTo(b.name));
      });

      _groupedStudents[academy] = groupedBySubject;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _groupedStudents.isEmpty
          ? const Center(child: Text("No hay alumnos para mostrar."))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _groupedStudents.length,
              itemBuilder: (context, academyIndex) {
                final academy = _groupedStudents.keys.elementAt(academyIndex);
                final subjects = _groupedStudents[academy]!;

                // --- STYLED ACADEMY TILE ---
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  clipBehavior: Clip.antiAlias, // Ensures the background color respects the border radius
                  child: ExpansionTile(
                    key: PageStorageKey(academy), // Helps to keep expansion state when scrolling
                    leading: const Icon(Icons.school_outlined, color: AppTheme.blueDark, size: 28),
                    title: Text(academy, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.blueDark)),
                    backgroundColor: AppTheme.blueSoft.withOpacity(0.2),
                    children: subjects.entries.map((subjectEntry) {
                      final subject = subjectEntry.key;
                      final studentList = subjectEntry.value;

                      // --- STYLED SUBJECT TILE ---
                      return ExpansionTile(
                        key: PageStorageKey('$academy-$subject'),
                        tilePadding: const EdgeInsets.only(left: 48, right: 24),
                        leading: const Icon(Icons.menu_book_outlined, color: AppTheme.bluePrimary),
                        title: Text(subject, style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.w600, fontSize: 16)),
                        backgroundColor: AppTheme.baseLight.withOpacity(0.5),
                        children: studentList.map((student) {
                          // --- STYLED STUDENT TILE ---
                          return ListTile(
                            contentPadding: const EdgeInsets.only(left: 56, right: 16, top: 4, bottom: 4),
                            leading: const Icon(Icons.person_outline, color: Colors.grey),
                            title: Text(student.name),
                            subtitle: Text('Boleta: ${student.boleta}'),
                            trailing: const Icon(Icons.chevron_right, size: 18),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => StudentDetailView(student: student)),
                              );
                            },
                          );
                        }).toList(),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
    );
  }
}
