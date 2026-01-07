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
  // Índice para animaciones o interacciones futuras
  int touchedIndex = -1;

  @override
  void initState() {
    super.initState();
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
        actions: [
          // Botón para refrescar manualmente si se desea
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => vm.processChartData(),
          )
        ],
      ),
      backgroundColor: AppTheme.baseLight,
      body: Builder(
        builder: (context) {
          if (vm.isLoading) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(vm.loadingMessage ?? "Cargando datos...", style: AppTheme.theme.textTheme.bodyMedium),
                ],
              ),
            );
          }

          if (vm.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  vm.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (vm.accreditedBySubject.isEmpty && vm.accreditedByAcademy.isEmpty) {
            return const Center(child: Text("No hay datos para el periodo seleccionado."));
          }

          // Calcular totales para el PieChart global
          final totalStats = _calculateTotalStats(vm.accreditedBySubject);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. SECCIÓN RESUMEN GLOBAL (PIE CHART)
                _SectionTitle(title: "Resumen Global del Periodo", context: context),
                const SizedBox(height: 10),
                _GlobalPieChartCard(
                  accredited: totalStats.accredited,
                  notAccredited: totalStats.notAccredited,
                  inProgress: totalStats.inProgress,
                ),

                const SizedBox(height: 32),

                // 2. SECCIÓN POR MATERIA (BAR CHART)
                _SectionTitle(title: "Rendimiento por Materia", context: context),
                const SizedBox(height: 10),
                ModernBarChartCard(stats: vm.accreditedBySubject),

                const SizedBox(height: 32),

                // 3. SECCIÓN POR ACADEMIA (BAR CHART)
                _SectionTitle(title: "Rendimiento por Academia", context: context),
                const SizedBox(height: 10),
                ModernBarChartCard(stats: vm.accreditedByAcademy),

                const SizedBox(height: 50),
              ],
            ),
          );
        },
      ),
    );
  }

  // Helper para sumar todo y mandarlo al PieChart
  Stats _calculateTotalStats(Map<String, Stats> data) {
    int acc = 0;
    int notAcc = 0;
    int inProg = 0;
    for (var stat in data.values) {
      acc += stat.accredited;
      notAcc += stat.notAccredited;
      inProg += stat.inProgress;
    }
    return (accredited: acc, notAccredited: notAcc, inProgress: inProg);
  }
}

// --- WIDGET DE TÍTULO DE SECCIÓN ---
class _SectionTitle extends StatelessWidget {
  final String title;
  final BuildContext context;
  const _SectionTitle({required this.title, required this.context});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppTheme.blueDark,
        ),
      ),
    );
  }
}

// --- 1. WIDGET DEL GRÁFICO DE PASTEL (NUEVO) ---
class _GlobalPieChartCard extends StatefulWidget {
  final int accredited;
  final int notAccredited;
  final int inProgress;

  const _GlobalPieChartCard({
    required this.accredited,
    required this.notAccredited,
    required this.inProgress,
  });

  @override
  State<_GlobalPieChartCard> createState() => _GlobalPieChartCardState();
}

class _GlobalPieChartCardState extends State<_GlobalPieChartCard> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final total = widget.accredited + widget.notAccredited + widget.inProgress;
    if (total == 0) return const SizedBox();

    return Card(
      elevation: 4,
      shadowColor: AppTheme.blueSoft.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // El Gráfico
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            touchedIndex = -1;
                            return;
                          }
                          touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: showingSections(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            // Las Leyendas
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Indicator(color: const Color(0xFF4CAF50), text: 'Acreditados', isSquare: false, textColor: const Color(0xff505050)),
                const SizedBox(height: 8),
                _Indicator(color: const Color(0xFFE53935), text: 'No Acreditados', isSquare: false, textColor: const Color(0xff505050)),
                const SizedBox(height: 8),
                _Indicator(color: AppTheme.bluePrimary, text: 'En Curso', isSquare: false, textColor: const Color(0xff505050)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> showingSections() {
    return List.generate(3, (i) {
      final isTouched = i == touchedIndex;
      final fontSize = isTouched ? 20.0 : 14.0;
      final radius = isTouched ? 60.0 : 50.0;
      const shadows = [Shadow(color: Colors.black, blurRadius: 2)];

      switch (i) {
        case 0: // Acreditados
          return PieChartSectionData(
            color: const Color(0xFF4CAF50),
            value: widget.accredited.toDouble(),
            title: '${widget.accredited}',
            radius: radius,
            titleStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.white, shadows: shadows),
          );
        case 1: // No Acreditados
          return PieChartSectionData(
            color: const Color(0xFFE53935),
            value: widget.notAccredited.toDouble(),
            title: '${widget.notAccredited}',
            radius: radius,
            titleStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.white, shadows: shadows),
          );
        case 2: // En Curso
          return PieChartSectionData(
            color: AppTheme.bluePrimary,
            value: widget.inProgress.toDouble(),
            title: '${widget.inProgress}',
            radius: radius,
            titleStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.white, shadows: shadows),
          );
        default:
          throw Error();
      }
    });
  }
}

// --- 2. WIDGET DE BARRAS MODERNAS ---
class ModernBarChartCard extends StatelessWidget {
  final Map<String, Stats> stats;
  const ModernBarChartCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final bool needsScroll = stats.length > 4;
    final double maxY = _getMaxY();
    // CORRECCIÓN: Intervalo dinámico. Si hay muchos alumnos, saltamos números para que no se peguen.
    final double interval = maxY > 15 ? (maxY / 5).ceilToDouble() : 1.0;

    return Card(
      elevation: 4,
      shadowColor: AppTheme.blueSoft.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _Indicator(color: const Color(0xFF66BB6A), text: 'Acreditado', size: 12),
                _Indicator(color: const Color(0xFFEF5350), text: 'No Acred.', size: 12),
                _Indicator(color: AppTheme.blueMedium, text: 'En Curso', size: 12),
              ],
            ),
            const SizedBox(height: 20),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: needsScroll ? stats.length * 90.0 : MediaQuery.of(context).size.width - 80,
                height: 300,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxY + (interval / 2), // Un poco de aire arriba
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBgColor: AppTheme.blueDark,
                        tooltipPadding: const EdgeInsets.all(8),
                        tooltipMargin: 8,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          String status;
                          switch (rodIndex) {
                            case 0: status = "Acreditados"; break;
                            case 1: status = "No Acreditados"; break;
                            case 2: status = "En Curso"; break;
                            default: status = "";
                          }
                          return BarTooltipItem(
                            '$status\n',
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            children: [
                              TextSpan(
                                text: (rod.toY).toInt().toString(),
                                style: const TextStyle(color: Colors.yellow, fontSize: 16, fontWeight: FontWeight.w900),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40, // Más espacio para números grandes
                          interval: interval, // <--- AQUÍ ESTÁ EL ARREGLO PRINCIPAL
                          getTitlesWidget: (value, meta) {
                            if (value % interval != 0) return Container(); // Limpieza extra
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              space: 4,
                              child: Text(
                                value.toInt().toString(),
                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 60,
                          getTitlesWidget: (value, meta) {
                            if (value < 0 || value >= stats.keys.length) return const SizedBox();
                            final title = stats.keys.elementAt(value.toInt());
                            final shortTitle = title.length > 10 ? '${title.substring(0, 8)}...' : title;

                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              space: 10,
                              child: Transform.rotate(
                                angle: -0.5,
                                child: Text(
                                  shortTitle,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppTheme.textSecondary),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: interval, // Alineamos la cuadrícula con los números
                      getDrawingHorizontalLine: (value) => FlLine(
                          color: AppTheme.baseLight,
                          strokeWidth: 1,
                          dashArray: [5, 5]
                      ),
                    ),
                    barGroups: stats.entries.toList().asMap().entries.map((entry) {
                      final index = entry.key;
                      final stat = entry.value.value;
                      return BarChartGroupData(
                        x: index,
                        groupVertically: false,
                        barRods: [
                          _makeRod(stat.accredited.toDouble(), const Color(0xFF66BB6A), const Color(0xFF43A047), maxY),
                          _makeRod(stat.notAccredited.toDouble(), const Color(0xFFEF5350), const Color(0xFFE53935), maxY),
                          _makeRod(stat.inProgress.toDouble(), AppTheme.blueMedium, AppTheme.bluePrimary, maxY),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getMaxY() {
    double maxVal = 0;
    for (var s in stats.values) {
      if (s.accredited > maxVal) maxVal = s.accredited.toDouble();
      if (s.notAccredited > maxVal) maxVal = s.notAccredited.toDouble();
      if (s.inProgress > maxVal) maxVal = s.inProgress.toDouble();
    }
    return maxVal == 0 ? 5 : maxVal;
  }

  BarChartRodData _makeRod(double y, Color color1, Color color2, double maxY) {
    return BarChartRodData(
      toY: y,
      gradient: LinearGradient(
        colors: [color1, color2],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      ),
      width: 12,
      borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
      backDrawRodData: BackgroundBarChartRodData(
        show: true,
        toY: maxY + (maxY * 0.1),
        color: AppTheme.baseLight.withValues(alpha: 0.5),
      ),
    );
  }
}

// --- WIDGET AUXILIAR PARA LEYENDAS ---
class _Indicator extends StatelessWidget {
  final Color color;
  final String text;
  final bool isSquare;
  final double size;
  final Color textColor;

  const _Indicator({
    required this.color,
    required this.text,
    this.isSquare = true,
    this.size = 16,
    this.textColor = const Color(0xff505050),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
            color: color,
            borderRadius: isSquare ? BorderRadius.circular(4) : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        )
      ],
    );
  }
}