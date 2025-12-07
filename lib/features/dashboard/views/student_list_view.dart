import 'package:flutter/material.dart';
import '../../../data/models/user_model.dart';
import '../../../theme/theme.dart';
import 'student_detail_view.dart';

class StudentListView extends StatelessWidget {
  final String title;
  final List<UserModel> students;

  const StudentListView({super.key, required this.title, required this.students});

  @override
  Widget build(BuildContext context) {
    // Sort students alphabetically by name
    students.sort((a, b) => a.name.compareTo(b.name));

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: students.isEmpty
          ? const Center(
              child: Text("No hay alumnos en esta categoría.", style: TextStyle(fontSize: 16, color: Colors.grey)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
<<<<<<< HEAD
                  elevation: 1,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.blueSoft,
                      child: Text(student.name.isNotEmpty ? student.name[0] : "?", style: const TextStyle(color: AppTheme.blueDark, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Boleta: ${student.boleta}"),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => StudentDetailView(student: student)),
=======
                  clipBehavior: Clip.antiAlias,
                  child: ExpansionTile(
                    key: PageStorageKey(academy),
                    leading: const Icon(Icons.school_outlined, color: AppTheme.blueDark, size: 28),
                    title: Text(academy, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.blueDark)),
                    backgroundColor: AppTheme.blueSoft.withValues(alpha:0.2),
                    children: subjects.entries.map((subjectEntry) {
                      final subject = subjectEntry.key;
                      final studentList = subjectEntry.value;

                      return ExpansionTile(
                        key: PageStorageKey('$academy-$subject'),
                        tilePadding: const EdgeInsets.only(left: 48, right: 24),
                        leading: const Icon(Icons.menu_book_outlined, color: AppTheme.bluePrimary),
                        title: Text(subject, style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.w600, fontSize: 16)),
                        backgroundColor: AppTheme.baseLight.withValues(alpha:0.5),
                        children: studentList.map((student) {
                          // --- FIX: Remove toUpperCase() ---
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
>>>>>>> b02e3f38a199391d13e8c793264fe648935ec0f9
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
