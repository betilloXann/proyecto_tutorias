import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/responsive_container.dart'; // <--- IMPORTAR
import '../../../core/widgets/primary_button.dart';
import '../../../data/repositories/auth_repository.dart';
import '../viewmodels/upload_evidence_viewmodel.dart';
import '../../../theme/theme.dart';

class UploadEvidenceView extends StatelessWidget {
  const UploadEvidenceView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => UploadEvidenceViewModel(
        authRepo: context.read<AuthRepository>(),
      ),
      child: Scaffold(
        backgroundColor: AppTheme.baseLight,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text("Nueva Evidencia",
              style: TextStyle(color: AppTheme.blueDark, fontWeight: FontWeight.bold)
          ),
          leading: Consumer<UploadEvidenceViewModel>(
            builder: (context, vm, _) => IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: AppTheme.blueDark, size: 20),
              onPressed: () {
                vm.clear();
                Navigator.pop(context);
              },
            ),
          ),
        ),
        // --- APLICANDO RESPONSIVE CONTAINER ---
        body: ResponsiveContainer(
          child: Consumer<UploadEvidenceViewModel>(
            builder: (context, vm, child) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: AppTheme.bluePrimary.withAlpha(25),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.bluePrimary.withAlpha(75))
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: AppTheme.bluePrimary),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              "Recuerda que tu evidencia debe estar firmada por el tutor asignado.",
                              style: TextStyle(color: AppTheme.blueDark, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    const Text("Materia y Profesor", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    const SizedBox(height: 10),

                    if (vm.isLoadingClasses)
                      const Center(child: LinearProgressIndicator())
                    else
                      _CustomDropdown(
                        hint: "Selecciona tu clase",
                        value: vm.selectedClassData,
                        items: vm.availableClasses.map((item) {
                          return DropdownMenuItem<Map<String, dynamic>>(
                            value: item,
                            child: Text(item['display'], style: const TextStyle(fontSize: 14)),
                          );
                        }).toList(),
                        onChanged: (val) => vm.setClass(val),
                        icon: Icons.school_outlined,
                      ),

                    const SizedBox(height: 20),

                    const Text("Mes a Reportar", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    const SizedBox(height: 10),
                    _CustomDropdown(
                      hint: "Selecciona el mes",
                      value: vm.selectedMonth,
                      items: vm.months.map((String mes) {
                        return DropdownMenuItem<String>(value: mes, child: Text(mes));
                      }).toList(),
                      onChanged: (val) => vm.setMonth(val),
                      icon: Icons.calendar_today_outlined,
                    ),

                    const SizedBox(height: 20),

                    const Text("Adjuntar Archivo", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    const SizedBox(height: 10),

                    InkWell(
                      onTap: vm.pickFile,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: vm.fileName != null ? Colors.green : AppTheme.blueSoft,
                                width: 2,
                                style: BorderStyle.solid
                            ),
                            boxShadow: [
                              BoxShadow(color: AppTheme.blueSoft.withAlpha(25), blurRadius: 10, offset: const Offset(0, 5))
                            ]
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: vm.fileName != null ? Colors.green.withAlpha(25) : AppTheme.baseLight,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                vm.fileName != null ? Icons.check : Icons.cloud_upload_outlined,
                                size: 40,
                                color: vm.fileName != null ? Colors.green : AppTheme.bluePrimary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              vm.fileName ?? "Toca para buscar PDF o Imagen",
                              style: TextStyle(
                                  color: vm.fileName != null ? Colors.green : AppTheme.textSecondary,
                                  fontWeight: FontWeight.w600
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (vm.fileName == null)
                              const Padding(
                                padding: EdgeInsets.only(top: 8.0),
                                child: Text("(Máx 5MB)", style: TextStyle(fontSize: 12, color: Colors.grey)),
                              )
                          ],
                        ),
                      ),
                    ),

                    if (vm.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
                          child: Row(children: [
                            const Icon(Icons.error, color: Colors.red, size: 20),
                            const SizedBox(width: 10),
                            Expanded(child: Text(vm.errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13))),
                          ]),
                        ),
                      ),

                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: vm.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : PrimaryButton(
                          text: "Subir Evidencia",
                          onPressed: () async {
                            final success = await vm.uploadEvidence();
                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("¡Evidencia enviada exitosamente!"), backgroundColor: Colors.green),
                              );
                              vm.clear();
                              Navigator.pop(context);
                            }
                          }
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CustomDropdown<T> extends StatelessWidget {
  final String hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final IconData icon;

  const _CustomDropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: AppTheme.blueSoft.withAlpha(50), blurRadius: 10, offset: const Offset(0, 4))
          ]
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.textSecondary),
              const SizedBox(width: 10),
              Text(hint, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
            ],
          ),
          icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.bluePrimary),
          items: items,
          onChanged: onChanged,
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}