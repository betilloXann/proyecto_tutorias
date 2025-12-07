import 'package:flutter/material.dart';
import '../../../data/models/user_model.dart';
import '../../../theme/theme.dart';
import 'student_detail_view.dart';

class StudentListView extends StatelessWidget {
  final String title;
  final List<UserModel> students;
  final Function(UserModel)? onAssign;

  const StudentListView({super.key, required this.title, required this.students, this.onAssign});

  @override
  Widget build(BuildContext context) {
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
                  elevation: 1,
                  child: Column(
                    children: [
                      ListTile(
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
                          );
                        },
                      ),
                      if (onAssign != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: TextButton.icon(
                            icon: const Icon(Icons.add_circle_outline, size: 18),
                            label: const Text("Asignar Materia"),
                            style: TextButton.styleFrom(foregroundColor: AppTheme.bluePrimary),
                            onPressed: () => onAssign!(student),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
