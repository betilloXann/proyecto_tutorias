import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/user_model.dart';
import '../../../theme/theme.dart';
import '../viewmodels/academy_home_viewmodel.dart';
import '../viewmodels/home_menu_viewmodel.dart';
import 'student_detail_view.dart';
import 'student_list_view.dart';
import 'subject_management_view.dart';

class AcademyHomeView extends StatelessWidget {
  const AcademyHomeView({super.key});

  void _navigateToStudentList(BuildContext context, String title, List<UserModel> students) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => StudentListView(title: title, students: students)),
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
        body: Consumer<AcademyViewModel>(
          builder: (context, vm, child) {
            if (vm.isLoading) return const Center(child: CircularProgressIndicator());

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Resumen de Alumnos", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.blueDark)),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: [
                      GestureDetector(
                        onTap: () => _navigateToStudentList(context, 'Pendientes de Asignación', vm.pendingStudents),
                        child: _buildSummaryCard('Pendientes', vm.pendingStudents.length.toString(), Icons.hourglass_top_outlined, Colors.orange.shade700),
                      ),
                      GestureDetector(
                        onTap: () => _navigateToStudentList(context, 'Alumnos en Curso', vm.assignedStudents),
                        child: _buildSummaryCard('En Curso', vm.assignedStudents.length.toString(), Icons.school_outlined, AppTheme.bluePrimary),
                      ),
                      GestureDetector(
                        onTap: () => _navigateToStudentList(context, 'Alumnos Acreditados', vm.accreditedStudents),
                        child: _buildSummaryCard('Acreditados', vm.accreditedStudents.length.toString(), Icons.check_circle_outlined, Colors.green.shade700),
                      ),
                      GestureDetector(
                        onTap: () => _navigateToStudentList(context, 'Alumnos No Acreditados', vm.notAccreditedStudents),
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
