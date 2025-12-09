import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/responsive_container.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../theme/theme.dart';
import '../viewmodels/department_home_viewmodel.dart';
import '../viewmodels/home_menu_viewmodel.dart';
import 'student_list_view.dart';
import 'bulk_upload_view.dart';

class DepartmentHomeView extends StatefulWidget {
  final UserModel user;
  const DepartmentHomeView({super.key, required this.user});

  @override
  State<DepartmentHomeView> createState() => _DepartmentHomeViewState();
}

// 1. Agregamos el Observer para detectar el ciclo de vida
class _DepartmentHomeViewState extends State<DepartmentHomeView> with WidgetsBindingObserver {
  late DepartmentHomeViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Registrar observer
    _viewModel = DepartmentHomeViewModel(context.read<AuthRepository>());
    _viewModel.loadDashboardData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Limpiar observer
    super.dispose();
  }

  // 2. Lógica de Refetch on Focus
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint("🔄 Volviendo a obtener los datos...");
      _viewModel.loadDashboardData();
    }
  }

  Future<void> _refreshData() async {
    await _viewModel.loadDashboardData();
  }

  void _navigateToStudentList(BuildContext context, String title, List<UserModel> students) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => StudentListView(title: title, students: students)),
    );
    _refreshData(); // Recargar al volver de la lista
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

              return RefreshIndicator(
                onRefresh: _refreshData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Resumen Global", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.blueDark)),
                      const SizedBox(height: 16),

                      // --- 3. DISEÑO: TOTAL ALUMNOS COMO BANNER ANCHO ---
                      GestureDetector(
                        onTap: () => _navigateToStudentList(context, 'Total Alumnos', vm.students),
                        child: SizedBox(
                          height: 100,
                          child: _HoverableSummaryCard(
                            title: 'Total Alumnos',
                            count: vm.totalStudents.toString(),
                            icon: Icons.groups_outlined,
                            color: Colors.blue.shade700,
                            isWide: true, // Modo ancho activado
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // --- GRID PARA EL RESTO DE TARJETAS (4 elementos restantes) ---
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.3,
                        children: [
                          GestureDetector(
                            onTap: () => _navigateToStudentList(context, 'Pre-registrados', vm.students.where((s) => s.status == 'PRE_REGISTRO').toList()),
                            child: _HoverableSummaryCard(
                              title: 'Pre-registrados',
                              count: vm.preRegisteredCount.toString(),
                              icon: Icons.person_add_alt_1_outlined,
                              color: Colors.purple.shade700,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _navigateToStudentList(context, 'Pendientes', vm.students.where((s) => s.status == 'PENDIENTE_ASIGNACION').toList()),
                            child: _HoverableSummaryCard(
                              title: 'Pendientes',
                              count: vm.pendingCount.toString(),
                              icon: Icons.hourglass_top_outlined,
                              color: Colors.orange.shade700,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _navigateToStudentList(context, 'En Curso', vm.students.where((s) => s.status == 'EN_CURSO').toList()),
                            child: _HoverableSummaryCard(
                              title: 'En Curso',
                              count: vm.inCourseCount.toString(),
                              icon: Icons.school_outlined,
                              color: AppTheme.bluePrimary,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _navigateToStudentList(context, 'Acreditados', vm.students.where((s) => s.status == 'ACREDITADO').toList()),
                            child: _HoverableSummaryCard(
                              title: 'Acreditados',
                              count: vm.accreditedCount.toString(),
                              icon: Icons.check_circle_outlined,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      )
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
          tooltip: "Carga Masiva de Alumnos",
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

// --- WIDGET TARJETA ACTUALIZADO ---
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
    this.isWide = false,
  });

  @override
  State<_HoverableSummaryCard> createState() => _HoverableSummaryCardState();
}

class _HoverableSummaryCardState extends State<_HoverableSummaryCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // Corrección del scale deprecado
    final transform = kIsWeb && _isHovered
        ? (Matrix4.identity()..scaleByDouble(1.05, 1.05, 1.05, 1.0))
        : Matrix4.identity();

    final duration = const Duration(milliseconds: 200);

    Widget cardContent;

    if (widget.isWide) {
      // Diseño Horizontal
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
      // Diseño Vertical (Grid)
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