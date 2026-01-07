import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/responsive_container.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../theme/theme.dart';
import '../viewmodels/department_home_viewmodel.dart';
import '../../dashboard/viewmodels/home_menu_viewmodel.dart';
import '../../students/views/student_list_view.dart';
import '../../operations/views/bulk_upload_view.dart';
import '../../reports/views/semester_report_view.dart';

class DepartmentHomeView extends StatefulWidget {
  final UserModel user;
  const DepartmentHomeView({super.key, required this.user});

  @override
  State<DepartmentHomeView> createState() => _DepartmentHomeViewState();
}

class _DepartmentHomeViewState extends State<DepartmentHomeView> with WidgetsBindingObserver {
  late DepartmentHomeViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _viewModel = DepartmentHomeViewModel(context.read<AuthRepository>());
    // loadDashboardData ya se llama en el init del VM
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _viewModel.loadDashboardData();
    }
  }

  Future<void> _refreshData() async {
    await _viewModel.loadDashboardData();
  }

  // Función genérica de navegación
  void _navigateToStudentList(BuildContext context, String title, List<UserModel> students) async {
    if (students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No hay alumnos en esta categoría para el periodo seleccionado."))
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => StudentListView(title: title, students: students)),
    );
    _refreshData();
  }

  @override
  Widget build(BuildContext context) {
    final menuViewModel = context.read<HomeMenuViewModel>();

    return ChangeNotifierProvider.value(
      value: _viewModel,
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
        body: ResponsiveContainer(
          child: Consumer<DepartmentHomeViewModel>(
            builder: (context, vm, child) {
              if (vm.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (vm.errorMessage != null) {
                return Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(vm.errorMessage!),
                    ElevatedButton(onPressed: _refreshData, child: const Text("Reintentar"))
                  ],
                ));
              }

              final academyStats = vm.studentsByAcademy.entries.toList();

              return RefreshIndicator(
                onRefresh: _refreshData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- HEADER Y SELECTOR DE PERIODO ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Resumen Global", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.blueDark)),

                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: vm.availablePeriods.contains(vm.selectedPeriod) ? vm.selectedPeriod : null,
                                hint: const Text("Periodo"),
                                items: vm.availablePeriods.map((period) {
                                  return DropdownMenuItem(
                                    value: period,
                                    child: Text(
                                        period,
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.bluePrimary)
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) vm.changePeriod(val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // TARJETA TOTAL
                      GestureDetector(
                        onTap: () => _navigateToStudentList(context, 'Total Alumnos', vm.allStudents),
                        child: SizedBox(
                          height: 100,
                          child: _HoverableSummaryCard(
                            title: 'Total Alumnos',
                            count: vm.totalStudents.toString(),
                            icon: Icons.groups_outlined,
                            color: Colors.blue.shade700,
                            isWide: true,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // GRID DE ESTATUS (Ahora con navegación real)
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.3,
                        children: [
                          GestureDetector(
                            onTap: () => _navigateToStudentList(
                                context,
                                'Sin Activar Cuenta',
                                vm.getStudentsByStatus('PRE_REGISTRO')
                            ),
                            child: _HoverableSummaryCard(
                              title: 'Alumnos Sin Activar Cuenta',
                              count: vm.preRegisteredCount.toString(),
                              icon: Icons.person_add_alt_1_outlined,
                              color: Colors.purple.shade700,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _navigateToStudentList(
                                context,
                                'Pendientes de Tutor',
                                vm.getStudentsByStatus('PENDIENTE_ASIGNACION')
                            ),
                            child: _HoverableSummaryCard(
                              title: 'Pendientes de Asignar Tutor',
                              count: vm.pendingCount.toString(),
                              icon: Icons.hourglass_top_outlined,
                              color: Colors.orange.shade700,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _navigateToStudentList(
                                context,
                                'En Curso',
                                vm.getStudentsByStatus('EN_CURSO')
                            ),
                            child: _HoverableSummaryCard(
                              title: 'Cursando',
                              count: vm.inCourseCount.toString(),
                              icon: Icons.school_outlined,
                              color: AppTheme.bluePrimary,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _navigateToStudentList(
                                context,
                                'Acreditados',
                                vm.getStudentsByStatus('ACREDITADO')
                            ),
                            child: _HoverableSummaryCard(
                              title: 'Acreditados',
                              count: vm.accreditedCount.toString(),
                              icon: Icons.check_circle_outlined,
                              color: Colors.green.shade700,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _navigateToStudentList(
                                context,
                                'No Acreditados',
                                vm.getStudentsByStatus('NO_ACREDITADO')
                            ),
                            child: _HoverableSummaryCard(
                              title: 'No Acreditados',
                              count: vm.notAccreditedCount.toString(),
                              icon: Icons.cancel_outlined,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // --- DESGLOSE POR ACADEMIA (ALUMNOS) ---
                      if (academyStats.isNotEmpty) ...[
                        const Text("Desglose por Academia (Alumnos)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.blueDark)),
                        const SizedBox(height: 16),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.5,
                          ),
                          itemCount: academyStats.length,
                          itemBuilder: (context, index) {
                            final academyName = academyStats[index].key;
                            final count = academyStats[index].value;

                            return GestureDetector(
                              onTap: () => _navigateToStudentList(
                                  context,
                                  academyName,
                                  vm.getStudentsByAcademy(academyName)
                              ),
                              child: _HoverableSummaryCard(
                                title: academyName,
                                count: count.toString(),
                                icon: Icons.business_outlined,
                                color: Colors.teal.shade700,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                      ],

                      const Text("Herramientas Adicionales", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.blueDark)),
                      const SizedBox(height: 16),

                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const SemesterReportView()));
                        },
                        child: const SizedBox(
                          height: 100,
                          child: _HoverableSummaryCard(
                            title: 'Fin de Semestre',
                            count: 'Reportes',
                            icon: Icons.assessment_outlined,
                            color: Colors.teal,
                            isWide: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BulkUploadView()),
            );
            _refreshData();
          },
          tooltip: "Carga Masiva",
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

// ... La clase _HoverableSummaryCard la dejas igual ...
class _HoverableSummaryCard extends StatefulWidget {
  final String title;
  final String count;
  final IconData icon;
  final Color color;
  final bool isWide;

  const _HoverableSummaryCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    this.isWide = false,
  });

  @override
  State<_HoverableSummaryCard> createState() => _HoverableSummaryCardState();
}

class _HoverableSummaryCardState extends State<_HoverableSummaryCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final transform = kIsWeb && _isHovered
        ? (Matrix4.identity()..scaleByDouble(1.05, 1.05, 1.05, 1.0))
        : Matrix4.identity();

    final duration = const Duration(milliseconds: 200);

    Widget cardContent;

    if (widget.isWide) {
      cardContent = Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(widget.icon, size: 40, color: widget.color),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(widget.count, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: widget.color)),
                Text(widget.title, style: TextStyle(fontSize: 16, color: widget.color.withValues(alpha:0.8))),
              ],
            ),
          ),
        ],
      );
    } else {
      cardContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(widget.icon, size: 32, color: widget.color),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.count, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: widget.color)),
              Text(widget.title, style: TextStyle(color: widget.color.withValues(alpha:0.8))),
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
            child: cardContent,
          ),
        ),
      ),
    );
  }
}