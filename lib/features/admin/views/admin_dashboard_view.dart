import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/admin_viewmodel.dart';

class AdminDashboardView extends StatelessWidget {
  const AdminDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    // Escuchamos el ViewModel para reaccionar a cambios (como isLoading)
    final viewModel = context.watch<AdminViewModel>();

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text("Panel de Administración"),
            backgroundColor: const Color(0xFF2F5A93),
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
              )
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildSectionTitle("Gestión de Personal"),
                const SizedBox(height: 10),
                _adminCard(
                  title: "Gestión de Academias",
                  subtitle: "Añadir o editar personal de Jefe de Academia",
                  icon: Icons.school,
                  color: Colors.blue,
                  onTap: () => _showAddStaffDialog(context, 'jefe_academia'),
                ),
                const SizedBox(height: 10),
                _adminCard(
                  title: "Añadir Personal de Tutorías",
                  subtitle: "Asignar responsable al departamento general",
                  icon: Icons.admin_panel_settings,
                  color: Colors.orange,
                  onTap: () => _showAddStaffDialog(context, 'tutorias'),
                ),
                
                const Divider(height: 40),
                _buildSectionTitle("Personal Asignado"),
                const SizedBox(height: 15),
                
                // LISTADO DE PERSONAL EN TIEMPO REAL
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: viewModel.staffStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text("No hay personal asignado todavía.", 
                          style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                      );
                    }

                    final staffList = snapshot.data!;
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: staffList.length,
                      itemBuilder: (context, index) {
                        final person = staffList[index];
                        final bool isJefe = person['role'] == 'jefe_academia';
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isJefe ? Colors.blue.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                              child: Icon(
                                isJefe ? Icons.school : Icons.admin_panel_settings,
                                color: isJefe ? Colors.blue : Colors.orange,
                              ),
                            ),
                            title: Text(person['name'] ?? 'Sin nombre', 
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(person['email_inst'] ?? 'Sin correo'),
                                Text(
                                  isJefe 
                                    ? "Academia: ${(person['academies'] as List?)?.join(', ') ?? 'N/A'}"
                                    : "Departamento: Tutorías General",
                                  style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),

                const Divider(height: 40),
                _buildSectionTitle("Herramientas de Desarrollo"),
                const SizedBox(height: 20),
                
                _mantenimientoButton(
                  text: "REGENERAR JEFES (V2)",
                  icon: Icons.refresh,
                  color: Colors.green,
                  onPressed: () => viewModel.runRegenerateStaff(),
                ),
                const SizedBox(height: 10),
                _mantenimientoButton(
                  text: "BORRAR SOLO ALUMNOS",
                  icon: Icons.delete_sweep,
                  color: Colors.redAccent,
                  onPressed: () => _confirmDelete(context, viewModel),
                ),
                const SizedBox(height: 10),
                _mantenimientoButton(
                  text: "GENERAR DATOS DE PRUEBA",
                  icon: Icons.people,
                  color: Colors.blueAccent,
                  onPressed: () => _showGenerationOptions(context, viewModel), // Nueva función
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
        
        if (viewModel.isLoading)
          const ModalBarrier(dismissible: false, color: Colors.black45),
        if (viewModel.isLoading)
          const Center(child: CircularProgressIndicator()),
      ],
    );
  }

  // --- WIDGETS DE APOYO ---

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title, 
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54)
      ),
    );
  }

  Widget _adminCard({
    required String title, 
    required String subtitle, 
    required IconData icon, 
    required Color color, 
    required VoidCallback onTap
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1), 
          child: Icon(icon, color: color)
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _mantenimientoButton({
    required String text, 
    required IconData icon, 
    required Color color, 
    required VoidCallback onPressed
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(text),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
        ),
      ),
    );
  }

  // --- DIÁLOGOS Y LÓGICA ---

  void _confirmDelete(BuildContext context, AdminViewModel vm) async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("⚠️ Confirmar borrado"),
        content: const Text("Esta acción eliminará permanentemente a los alumnos de la base de datos y sus cuentas de acceso."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("CANCELAR")),
          TextButton(
            onPressed: () => Navigator.pop(c, true), 
            child: const Text("SÍ, BORRAR", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );

    if (proceed == true) {
      final res = await vm.runDeleteStudents();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Limpieza completada: ${res['db']} registros eliminados."))
        );
      }
    }
  }

  void _showAddStaffDialog(BuildContext context, String initialRole) {
    final viewModel = context.read<AdminViewModel>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    
    final academiesList = ['COMPUTACION', 'LAB. ELECT. Y CONTROL', 'INFORMATICA'];
    String selectedAcademy = academiesList[0];
    String selectedRole = initialRole;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(selectedRole == 'jefe_academia' 
              ? "Nuevo Jefe de Academia" 
              : "Nuevo Personal de Tutorías"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  decoration: const InputDecoration(labelText: "Perfil de Usuario"),
                  items: const [
                    DropdownMenuItem(value: 'jefe_academia', child: Text("Jefe de Academia")),
                    DropdownMenuItem(value: 'tutorias', child: Text("Personal de Tutorías")),
                  ],
                  onChanged: (val) => setState(() => selectedRole = val!),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: "Nombre Completo", 
                    icon: Icon(Icons.person) 
                  ),
                ),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(
                    labelText: "Correo Institucional", 
                    icon: Icon(Icons.email)
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                if (selectedRole == 'jefe_academia') ...[
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    initialValue: selectedAcademy,
                    decoration: const InputDecoration(
                      labelText: "Academia a Cargo", 
                      icon: Icon(Icons.account_balance)
                    ),
                    items: academiesList.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                    onChanged: (val) => setState(() => selectedAcademy = val!),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCELAR"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty || emailCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Por favor llena todos los campos"))
                  );
                  return;
                }

                await viewModel.createSingleStaff(
                  email: emailCtrl.text.trim(),
                  name: nameCtrl.text.trim(),
                  role: selectedRole,
                  academy: selectedRole == 'jefe_academia' ? selectedAcademy : '',
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Usuario creado exitosamente"))
                  );
                }
              },
              child: const Text("GUARDAR"),
            ),
          ],
        ),
      ),
    );
  }

  void _showGenerationOptions(BuildContext context, AdminViewModel vm) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) =>
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Selecciona el escenario de prueba",
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.today, color: Colors.blue),
                  title: const Text("Generar Semestre ACTUAL"),
                  subtitle: const Text(
                      "Crea alumnos 'En Curso' para el periodo actual."),
                  onTap: () {
                    Navigator.pop(ctx);
                    vm.runGenerateSampleStudents(
                        periodOffset: 0); // Offset 0 = Hoy
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.history, color: Colors.orange),
                  title: const Text("Generar Semestre PASADO"),
                  subtitle: const Text(
                      "Crea registros históricos para probar los filtros."),
                  onTap: () {
                    Navigator.pop(ctx);
                    vm.runGenerateSampleStudents(
                        periodOffset: -1); // Offset -1 = Semestre anterior
                  },
                ),
              ],
            ),
          ),
    );
  }
}