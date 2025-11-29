import 'package:flutter/material.dart';
import '../../../theme/theme.dart';

class AcademyHomeView extends StatelessWidget {
  const AcademyHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Jefatura de Academia")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school, size: 60, color: AppTheme.bluePrimary),
            Text("Vista de Jefe de Academia"),
          ],
        ),
      ),
    );
  }
}