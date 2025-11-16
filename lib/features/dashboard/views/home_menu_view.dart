import 'package:flutter/material.dart';
import 'package:proyecto_tutorias/widgets/primary_button.dart';

class HomeMenuView extends StatelessWidget {
  const HomeMenuView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE6EEF8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Bienvenido"),
        actions: [IconButton(onPressed: () {}, icon: Icon(Icons.person))],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _item(Icons.calendar_today, "Mis Tutorías"),
            _item(Icons.person_add_alt_1, "Solicitar Tutor"),
            _item(Icons.history, "Historial"),
            _item(Icons.notifications, "Avisos"),
          ],
        ),
      ),
    );
  }

  Widget _item(IconData icon, String title) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40),
          SizedBox(height: 10),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
