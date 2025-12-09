import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../theme/theme.dart';
import '../viewmodels/semester_report_viewmodel.dart';

class SemesterChartsView extends StatefulWidget {
  const SemesterChartsView({super.key});

  @override
  State<SemesterChartsView> createState() => _SemesterChartsViewState();
}

class _SemesterChartsViewState extends State<SemesterChartsView> {
  @override
  void initState() {
    super.initState();
    // Iniciamos el procesamiento de datos cuando la vista se construye
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SemesterReportViewModel>().processChartData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SemesterReportViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gráficos de Rendimiento'),
      ),
      body: Builder(
        builder: (context) {
          if (vm.isLoading) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(vm.loadingMessage ?? "Cargando datos..."),
                ],
              ),
            );
          }

          if (vm.errorMessage != null) {
            return Center(child: Text(vm.errorMessage!, style: const TextStyle(color: Colors.red)));
          }

          if (vm.accreditedBySubject.isEmpty && vm.accreditedByAcademy.isEmpty) {
            return const Center(child: Text("No hay datos suficientes para mostrar los gráficos."));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text("Rendimiento por Materia", style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                SizedBox(
                  height: 350,
                  child: BarChartCard(stats: vm.accreditedBySubject),
                ),
                const SizedBox(height: 32),
                Text("Rendimiento por Academia", style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                 SizedBox(
                  height: 350,
                  child: BarChartCard(stats: vm.accreditedByAcademy),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// --- WIDGET REUTILIZABLE PARA LA TARJETA DEL GRÁFICO ---
class BarChartCard extends StatelessWidget {
  final Map<String, Stats> stats;
  const BarChartCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppTheme.baseLight,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                tooltipBgColor: Colors.blueGrey,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final title = stats.keys.elementAt(group.x.toInt());
                  final value = rod.toY.round();
                  final type = rodIndex == 0 ? "Acreditados" : "No Acreditados";
                  return BarTooltipItem(
                    '$title\n$type: $value',
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 100, // Espacio para etiquetas
                  getTitlesWidget: (value, meta) {
                    final title = stats.keys.elementAt(value.toInt());
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 8.0,
                      child: Text(title, style: const TextStyle(fontSize: 10), maxLines: 2, overflow: TextOverflow.ellipsis),
                      angle: -0.5, // Rotación para mejor legibilidad
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            gridData: const FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 5),
            barGroups: stats.entries.toList().asMap().entries.map((entry) {
              final index = entry.key;
              final stat = entry.value.value;
              return BarChartGroupData(
                x: index,
                barRods: [
                  // Barra de Acreditados
                  BarChartRodData(
                    toY: stat.accredited.toDouble(),
                    color: Colors.green,
                    width: 16,
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                  ),
                  // Barra de No Acreditados
                  BarChartRodData(
                    toY: stat.notAccredited.toDouble(),
                    color: Colors.red,
                    width: 16,
                     borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
