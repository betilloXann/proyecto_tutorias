import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/responsive_container.dart';
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
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("Cancelar")
          ),
          ElevatedButton(
            onPressed: () {
              onConfirm();
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange), // Cambio a Naranja (Precaución)
            child: const Text("Confirmar Cierre", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SemesterReportViewModel(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestión de Semestres'),
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
                        child: Text(
                            vm.errorMessage!,
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)
                        ),
                      ),

                    // --- NUEVO: SELECTOR DE PERIODO ---
                    _buildPeriodSelector(context, vm),

                    const SizedBox(height: 24),
                    Text("Reportes y Estadísticas", style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),

                    // Tarjeta 1: Excel
                    _buildReportCard(
                      context: context,
                      title: "Descargar Excel (${vm.selectedPeriod})", // Muestra el periodo seleccionado
                      subtitle: "Genera el reporte detallado de calificaciones para el periodo seleccionado.",
                      icon: Icons.table_chart_outlined,
                      color: Colors.green,
                      onTap: () async {
                        await vm.generateExcelReport();
                        if (context.mounted && vm.errorMessage == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Reporte ${vm.selectedPeriod} descargado."))
                          );
                        }
                      },
                    ),

                    const SizedBox(height: 16),

                    // Tarjeta 2: Gráficos
                    _buildReportCard(
                      context: context,
                      title: "Gráficos de Rendimiento",
                      subtitle: "Visualiza la data académica del periodo ${vm.selectedPeriod}.",
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

                    // --- MODIFICADO: SECCIÓN DE CIERRE DE CICLO ---
                    Text("Administración del Ciclo", style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),

                    _buildReportCard(
                      context: context,
                      title: "Cerrar Ciclo Escolar ${vm.selectedPeriod}",
                      subtitle: "Archiva el semestre actual y prepara el sistema para el siguiente. Los datos NO se borran, se guardan en el historial.",
                      icon: Icons.archive_outlined, // Icono de archivo en lugar de basura
                      color: Colors.orange.shade800, // Color de advertencia, no de peligro mortal
                      onTap: () {
                        _showConfirmationDialog(context,
                            title: "¿Cerrar Ciclo ${vm.selectedPeriod}?",
                            content: "Al confirmar, el sistema avanzará al siguiente periodo escolar. Todos los alumnos actuales serán archivados bajo el periodo '${vm.selectedPeriod}' pero permanecerán en la base de datos.",
                            onConfirm: () async {
                              final result = await vm.closeSemester();
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

  // --- NUEVO WIDGET: El Dropdown del Semestre ---
  Widget _buildPeriodSelector(BuildContext context, SemesterReportViewModel vm) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withAlpha((0.3 * 255).round()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.primary),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Periodo Visualizado",
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 4),
              Text(
                vm.selectedPeriod,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          DropdownButton<String>(
            value: vm.availablePeriods.contains(vm.selectedPeriod) ? vm.selectedPeriod : null,
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            underline: const SizedBox(), // Quita la línea fea por defecto
            style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 16),
            onChanged: (String? newValue) {
              if (newValue != null) {
                vm.changePeriod(newValue);
              }
            },
            items: vm.availablePeriods.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text("Periodo $value"),
              );
            }).toList(),
          ),
        ],
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha((0.1 * 255).round()),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: color),
              ),
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
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}