import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/responsive_container.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../theme/theme.dart';
import '../viewmodels/bulk_upload_viewmodel.dart';

class BulkUploadView extends StatelessWidget {
  const BulkUploadView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => BulkUploadViewModel(authRepo: context.read<AuthRepository>()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Carga Masiva de Alumnos"),
        ),
        body: Consumer<BulkUploadViewModel>(
          builder: (context, vm, child) {
            // --- MOSTRAR DIÁLOGO DE ÉXITO ---
            if (vm.isSuccess) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text("Proceso Completado"),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 50),
                        const SizedBox(height: 16),
                        Text(vm.progressMessage, textAlign: TextAlign.center),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          vm.reset();
                        },
                        child: const Text("Cerrar"),
                      ),
                    ],
                  ),
                );
              });
            }

            return ResponsiveContainer(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_upload_outlined, size: 80, color: AppTheme.bluePrimary),
                      const SizedBox(height: 20),
                      const Text(
                        "Selecciona el archivo de Excel",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "El sistema registrará a los nuevos alumnos y sus materias reprobadas para el periodo seleccionado.",
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // --- NUEVO: SELECTOR DE PERIODO ---
                      // Esto permite definir a qué semestre corresponden las materias reprobadas
                      _buildPeriodSelector(context, vm),

                      const SizedBox(height: 24),

                      OutlinedButton.icon(
                        icon: const Icon(Icons.file_present_rounded),
                        label: Text(vm.fileName ?? "Seleccionar archivo .xlsx"),
                        onPressed: vm.isLoading ? null : vm.pickFile,
                        style: OutlinedButton.styleFrom(minimumSize: const Size(250, 50)),
                      ),
                      const SizedBox(height: 24),

                      ElevatedButton.icon(
                        icon: const Icon(Icons.upload),
                        label: const Text("Iniciar Proceso"),
                        onPressed: vm.fileName == null || vm.isLoading ? null : vm.processAndUpload,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.blueDark,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(250, 50),
                        ),
                      ),
                      const SizedBox(height: 32),

                      if (vm.isLoading)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 16),
                              Text(vm.progressMessage, textAlign: TextAlign.center),
                            ],
                          ),
                        ),

                      if (vm.errorMessage != null)
                        Text(vm.errorMessage!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // --- WIDGET AUXILIAR PARA EL DROPDOWN ---
  Widget _buildPeriodSelector(BuildContext context, BulkUploadViewModel vm) {
    // Generamos una lista de periodos cercanos (Año actual +/- 1)
    // Ejemplo si es 2026: [25/1, 25/2, 26/1, 26/2, 27/1, 27/2]
    final currentYear = DateTime.now().year;
    final List<String> options = [];

    for (int year = currentYear - 1; year <= currentYear + 1; year++) {
      final shortYear = year % 100; // Toma los últimos 2 dígitos (2026 -> 26)
      options.add('$shortYear/1');
      options.add('$shortYear/2');
    }

    return Container(
      width: 250, // Mismo ancho que los botones
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.bluePrimary.withAlpha(100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Periodo a cargar:",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: options.contains(vm.targetPeriod) ? vm.targetPeriod : null,
              hint: const Text("Seleccionar Periodo"),
              items: options.map((period) {
                return DropdownMenuItem(
                  value: period,
                  child: Text(
                    "Periodo $period",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.blueDark),
                  ),
                );
              }).toList(),
              onChanged: vm.isLoading
                  ? null
                  : (val) {
                if (val != null) vm.setTargetPeriod(val);
              },
            ),
          ),
        ],
      ),
    );
  }
}