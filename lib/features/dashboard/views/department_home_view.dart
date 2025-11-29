import 'package:flutter/material.dart';
import '../../../theme/theme.dart'; // Tu tema

class DepartmentHomeView extends StatelessWidget {
  const DepartmentHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Panel Administrativo")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.admin_panel_settings, size: 60, color: AppTheme.bluePrimary),
            Text("Vista de Depto. Tutorías / Gestión"),
          ],
        ),
      ),
    );
  }
}