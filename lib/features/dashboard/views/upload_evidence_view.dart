import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/primary_button.dart';
import '../viewmodels/upload_evidence_viewmodel.dart'; // Importa el VM

class UploadEvidenceView extends StatelessWidget {
  const UploadEvidenceView({super.key});

  @override
  Widget build(BuildContext context) {
    // Usamos watch para reconstruir la pantalla cuando cambie el estado
    final vm = context.watch<UploadEvidenceViewModel>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFE6EEF8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Subir Evidencia", style: TextStyle(color: Color(0xFF2F5A93), fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2F5A93)),
          onPressed: () {
            vm.clear(); // Limpiamos al salir
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Completa la información para reportar tu avance mensualmente."),
            const SizedBox(height: 20),

            // --- 1. SELECCIONAR MATERIA ---
            const Text("Materia Asignada", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  hint: const Text("Selecciona una materia"),
                  value: vm.selectedSubject, // Leemos del VM
                  items: vm.subjects.map((String materia) {
                    return DropdownMenuItem<String>(value: materia, child: Text(materia));
                  }).toList(),
                  onChanged: (val) => vm.setSubject(val), // Avisamos al VM
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --- 2. SELECCIONAR MES ---
            const Text("Mes a Reportar", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  hint: const Text("Selecciona el mes"),
                  value: vm.selectedMonth, // Leemos del VM
                  items: vm.months.map((String mes) {
                    return DropdownMenuItem<String>(value: mes, child: Text(mes));
                  }).toList(),
                  onChanged: (val) => vm.setMonth(val), // Avisamos al VM
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --- 3. SUBIR ARCHIVO ---
            const Text("Evidencia (Foto firmada)", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            InkWell(
              onTap: vm.pickFile, // Acción del VM
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      vm.selectedFile != null ? Icons.check_circle : Icons.cloud_upload,
                      size: 50,
                      color: vm.selectedFile != null ? Colors.green : Colors.blue,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      vm.fileName ?? "Toca para buscar archivo...",
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            // Mensaje de Error (Si existe)
            if (vm.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(vm.errorMessage!, style: const TextStyle(color: Colors.red)),
              ),

            const SizedBox(height: 40),

            // --- BOTÓN ENVIAR ---
            SizedBox(
              width: double.infinity,
              height: 50,
              child: vm.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : PrimaryButton(
                  text: "Enviar Evidencia",
                  onPressed: () async {
                    final success = await vm.uploadEvidence();
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Evidencia subida correctamente"), backgroundColor: Colors.green),
                      );
                      vm.clear();
                      Navigator.pop(context);
                    }
                  }
              ),
            ),
          ],
        ),
      ),
    );
  }
}