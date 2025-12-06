import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/user_model.dart';
import '../../../theme/theme.dart';
import '../../../data/repositories/auth_repository.dart';
import '../viewmodels/department_home_viewmodel.dart';
// Importamos la vista de detalle para poder navegar
import 'student_detail_view.dart';

class DepartmentHomeView extends StatelessWidget {
  const DepartmentHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    // Inyectamos el ViewModel aquí mismo
    return ChangeNotifierProvider(
      create: (context) => DepartmentHomeViewModel(context.read<AuthRepository>()),
      child: const _DepartmentContent(),
    );
  }
}

class _DepartmentContent extends StatefulWidget {
  const _DepartmentContent();

  @override
  State<_DepartmentContent> createState() => _DepartmentContentState();
}

class _DepartmentContentState extends State<_DepartmentContent> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DepartmentHomeViewModel>();
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: AppTheme.baseLight,
      appBar: AppBar(
        title: const Text("Departamento de Tutorías"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: vm.loadDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
              onPressed: () {
                vm.logout(onDone: () {
                  if (!mounted) return;
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                        (route) => false,
                  );
                });
              },
          ),
        ],
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: vm.loadDashboardData,
        child: SingleChildScrollView(
          // APLICAMOS EL FIX DEL TECLADO AQUÍ
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. SECCIÓN DE ESTADÍSTICAS
              const Text("Resumen Global", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.blueDark)),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                shrinkWrap: true,
                childAspectRatio: 1.5,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _StatCard(title: "Total Alumnos", count: vm.totalStudents, color: Colors.blueGrey, icon: Icons.groups),
                  _StatCard(title: "Pendientes", count: vm.pendingCount, color: Colors.orange, icon: Icons.assignment_late),
                  _StatCard(title: "En Curso", count: vm.inCourseCount, color: AppTheme.bluePrimary, icon: Icons.school),
                  _StatCard(title: "Acreditados", count: vm.accreditedCount, color: Colors.green, icon: Icons.check_circle),
                ],
              ),

              const SizedBox(height: 24),

              // 2. BUSCADOR
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: "Buscar por nombre o boleta...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onChanged: (val) => vm.searchStudent(val),
              ),

              const SizedBox(height: 16),

              // 3. LISTADO DE RESULTADOS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Directorio de Alumnos", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.blueDark)),
                  Text("${vm.students.length} resultados", style: const TextStyle(color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 10),

              if (vm.students.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(30), child: Text("No se encontraron alumnos.")))
              else
                ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: vm.students.length,
                  itemBuilder: (context, index) {
                    final student = vm.students[index];
                    return _StudentListTile(student: student);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- WIDGETS AUXILIARES ---

class _StatCard extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final IconData icon;

  const _StatCard({required this.title, required this.count, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: color.withAlpha(30), blurRadius: 8, offset: const Offset(0, 4))],
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(count.toString(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey)),
            ],
          )
        ],
      ),
    );
  }
}

class _StudentListTile extends StatelessWidget {
  final UserModel student;
  const _StudentListTile({required this.student});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.blueSoft,
          child: Text(student.name.isNotEmpty ? student.name[0] : "?", style: const TextStyle(color: AppTheme.blueDark, fontWeight: FontWeight.bold)),
        ),
        title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(student.boleta, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 2),
            _StatusBadge(status: student.status),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => StudentDetailView(student: student)),
          );
        },
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'ACREDITADO': color = Colors.green; break;
      case 'NO_ACREDITADO': color = Colors.red; break;
      case 'EN_CURSO': color = AppTheme.bluePrimary; break;
      default: color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          color: color.withAlpha(30),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(100))
      ),
      child: Text(
          status.replaceAll('_', ' '),
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)
      ),
    );
  }
}