import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../theme/theme.dart';
import '../viewmodels/department_home_viewmodel.dart';
import '../viewmodels/home_menu_viewmodel.dart';
import 'student_list_view.dart';

class DepartmentHomeView extends StatelessWidget {
  final UserModel user;
  const DepartmentHomeView({super.key, required this.user});

  void _navigateToStudentList(BuildContext context, String title, List<UserModel> students) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => StudentListView(title: title, students: students)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final menuViewModel = context.read<HomeMenuViewModel>();

    return ChangeNotifierProvider(
      create: (context) => DepartmentHomeViewModel(context.read<AuthRepository>()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Departamento de Tutorías"),
          actions: [
            IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  await menuViewModel.logout();
                  if (!context.mounted) return;
                  navigator.pushNamedAndRemoveUntil('/login', (route) => false);
                }
            )
          ],
        ),
        body: Consumer<DepartmentHomeViewModel>(
          builder: (context, vm, child) {
            if (vm.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (vm.errorMessage != null) {
              return Center(child: Text(vm.errorMessage!));
            }
            
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Resumen Global", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.blueDark)),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.3, // <-- FIX: Adjusted for more vertical space
                    children: [
                      GestureDetector(
                        onTap: () => _navigateToStudentList(context, 'Total Alumnos', vm.students),
                        child: _buildSummaryCard('Total Alumnos', vm.totalStudents.toString(), Icons.groups_outlined, Colors.blue.shade700),
                      ),
                      GestureDetector(
                        onTap: () => _navigateToStudentList(context, 'Pre-registrados', vm.students.where((s) => s.status == 'PRE_REGISTRO').toList()),
                        child: _buildSummaryCard('Pre-registrados', vm.preRegisteredCount.toString(), Icons.person_add_alt_1_outlined, Colors.purple.shade700),
                      ),
                      GestureDetector(
                        onTap: () => _navigateToStudentList(context, 'Pendientes', vm.students.where((s) => s.status == 'PENDIENTE_ASIGNACION').toList()),
                        child: _buildSummaryCard('Pendientes', vm.pendingCount.toString(), Icons.hourglass_top_outlined, Colors.orange.shade700),
                      ),
                      GestureDetector(
                        onTap: () => _navigateToStudentList(context, 'En Curso', vm.students.where((s) => s.status == 'EN_CURSO').toList()),
                        child: _buildSummaryCard('En Curso', vm.inCourseCount.toString(), Icons.school_outlined, AppTheme.bluePrimary),
                      ),
                      GestureDetector(
                        onTap: () => _navigateToStudentList(context, 'Acreditados', vm.students.where((s) => s.status == 'ACREDITADO').toList()),
                        child: _buildSummaryCard('Acreditados', vm.accreditedCount.toString(), Icons.check_circle_outlined, Colors.green.shade700),
                      ),
                    ],
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String count, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(50))
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
                Text(title, style: TextStyle(color: color.withOpacity(0.8))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
