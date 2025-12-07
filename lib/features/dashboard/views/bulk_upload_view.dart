import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
            // --- NEW: Show success dialog --- 
            if (vm.isSuccess) {
              // Use addPostFrameCallback to show dialog after build
              WidgetsBinding.instance.addPostFrameCallback((_) {
                showDialog(
                  context: context,
                  barrierDismissible: false, // User must tap button
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
                          Navigator.of(dialogContext).pop(); // Close the dialog
                          vm.reset(); // Reset the viewmodel state
                        },
                        child: const Text("Cerrar"),
                      ),
                    ],
                  ),
                );
              });
            }

            return Center(
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
                      "El sistema registrará a los nuevos alumnos y sus materias. Los alumnos existentes no serán modificados.",
                      style: TextStyle(color: Colors.grey), 
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

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
            );
          },
        ),
      ),
    );
  }
}
