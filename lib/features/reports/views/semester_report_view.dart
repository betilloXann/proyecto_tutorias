import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/responsive_container.dart';
// Eliminado: import '../../../data/repositories/auth_repository.dart'; <--- Ya no se necesita
import '../viewmodels/semester_report_viewmodel.dart';
import 'semester_charts_view.dart';

class SemesterReportView extends StatelessWidget {
  const SemesterReportView({super.key});

  void _showConfirmationDialog(BuildContext context, {
    required String title,
    required String content,
    required Function() onConfirm
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () {
              onConfirm();
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Confirmar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // --- CORRECCIÓN AQUÍ ---
      // Ya no pasamos 'authRepo' porque el constructor ya no lo pide
      create: (context) => SemesterReportViewModel(),
      
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reportes de Fin de Semestre'),
        ),
        body: Consumer<SemesterReportViewModel>(
          builder: (context, vm, child) {
            if (vm.isLoading) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(vm.loadingMessage ?? "Cargando..."),
                  ],
                ),
              );
            }

            return ResponsiveContainer(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                      if (vm.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(vm.errorMessage!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ),
                    Text("Reporte General", style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    _buildReportCard(
                      context: context,
                      title: "Generar Reporte en Excel",
                      subtitle: "Exporta un archivo Excel con el resumen de todos los alumnos, sus materias, estatus y calificaciones.",
                      icon: Icons.table_chart_outlined,
                      color: Colors.green,
                      onTap: () async {
                        await vm.generateExcelReport();
                        if (context.mounted && vm.errorMessage == null) {
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Descarga iniciada.")));
                        } else if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(vm.errorMessage!), backgroundColor: Colors.red));
                        }
                      },
                    ),
                    const Divider(height: 48),
                    Text("Gráficos", style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    _buildReportCard(
                      context: context,
                      title: "Ver Gráficos de Rendimiento",
                      subtitle: "Visualiza gráficos interactivos sobre el rendimiento de los alumnos por materia y academia.",
                      icon: Icons.bar_chart_outlined,
                      color: Colors.blue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChangeNotifierProvider.value(
                              value: vm,
                              child: const SemesterChartsView(),
                            ),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 48),
                    Text("Acciones de Limpieza", style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    _buildReportCard(
                      context: context,
                      title: "Eliminar Todos los Alumnos",
                      subtitle: "Esta acción eliminará permanentemente a TODOS los alumnos con rol de estudiante.",
                      icon: Icons.delete_sweep_outlined,
                      color: Colors.red,
                      onTap: () {
                        _showConfirmationDialog(context,
                          title: "¿Confirmar Eliminación Masiva?",
                          content: "Esta acción es irreversible y eliminará a TODOS los alumnos. ¿Deseas continuar?",
                          onConfirm: () async {
                            final result = await vm.deleteAllStudents();
                            if (context.mounted && result != null) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
                            }
                          }
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildReportCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}