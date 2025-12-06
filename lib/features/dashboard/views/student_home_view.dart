import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../data/models/user_model.dart';
import '../../../theme/theme.dart';
import '../viewmodels/home_menu_viewmodel.dart';
import 'upload_evidence_view.dart';
import 'subject_list_view.dart';
import '../../../data/services/pdf_generator_service.dart'; // <--- AGREGAR ESTO

class StudentHomeView extends StatelessWidget {
  final UserModel user;

  const StudentHomeView({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<HomeMenuViewModel>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.baseLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          // --- NEW: Button to see available subjects ---
          IconButton(
            icon: const Icon(Icons.menu_book_outlined, color: AppTheme.blueDark),
            tooltip: "Ver Materias Disponibles",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SubjectListView()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.blueDark),
            onPressed: () async {
              await viewModel.logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Hola,", style: theme.textTheme.titleLarge?.copyWith(color: AppTheme.textSecondary, fontSize: 20)),
            Text(user.name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.blueDark)),

            const SizedBox(height: 30),

            _StatusCard(status: user.status),

            const SizedBox(height: 20),

            _ClassesList(studentUid: user.id),

            const SizedBox(height: 30),

            Text("Acciones Rápidas", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 15),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _ActionItem(
                  icon: Icons.upload_file,
                  label: "Subir Evidencia",
                  color: AppTheme.bluePrimary,
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const UploadEvidenceView())
                    );
                  },
                ),
                _ActionItem(
                  icon: Icons.history, // Regresamos el Historial o lo que tenías antes
                  label: "Historial",
                  color: AppTheme.purpleMist,
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// WIDGETS PRIVADOS
// ==========================================

class _StatusCard extends StatelessWidget {
  final String status;
  const _StatusCard({required this.status});

  @override
  Widget build(BuildContext context) {
    Color cardColor;
    String title;
    String desc;
    IconData icon;

    switch (status) {
      case 'PENDIENTE_ASIGNACION':
        cardColor = Colors.orange;
        title = "Asignación Pendiente";
        desc = "Estamos validando tu dictamen y asignando un tutor.";
        icon = Icons.hourglass_top;
        break;
      case 'EN_CURSO':
        cardColor = AppTheme.bluePrimary;
        title = "Tutoría En Curso";
        desc = "Tienes un tutor asignado. Recuerda subir tus evidencias.";
        icon = Icons.school;
        break;
      case 'ACREDITADO':
        cardColor = Colors.green;
        title = "¡Acreditado!";
        desc = "Felicidades, has completado tu recuperación";
        icon = Icons.check_circle;
        break;
      default:
        cardColor = AppTheme.textDisabled;
        title = "Estatus Desconocido";
        desc = "Contacta al administrador.";
        icon = Icons.help;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: cardColor.withAlpha(100), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Estatus Actual", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
              Icon(icon, color: Colors.white, size: 28),
            ],
          ),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(desc, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

class _WaitingCard extends StatelessWidget {
  const _WaitingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.baseLight),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(color: AppTheme.baseLight, shape: BoxShape.circle),
          child: const Icon(Icons.person_search, color: AppTheme.textSecondary),
        ),
        const SizedBox(width: 15),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Buscando Tutor...", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          Text("Te notificaremos cuando se asigne.", style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        ])),
      ]),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionItem({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0,2))],
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withAlpha(25), shape: BoxShape.circle),
            child: Icon(icon, size: 30, color: color),
          ),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        ]),
      ),
    );
  }
}

class _ClassesList extends StatelessWidget {
  final String studentUid;

  const _ClassesList({required this.studentUid});

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance.collection('enrollments').where('uid', isEqualTo: studentUid);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Text("Error cargando horario");
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: LinearProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const _WaitingCard();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Mis Clases y Horarios", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.blueDark)),
            const SizedBox(height: 10),
            ...docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              //String academiaMateria = data['academy'] ?? "Ingeniería Informática";

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 5, offset: const Offset(0, 4))]
                ),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(color: AppTheme.baseLight, shape: BoxShape.circle),
                    child: const Icon(Icons.book, color: AppTheme.bluePrimary),
                  ),
                  const SizedBox(width: 15),
                  // INFO DE LA MATERIA
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(data['subject'] ?? 'Materia', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text("Prof: ${data['professor']}", style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 6),
                    Text(data['schedule'] ?? '--:--', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ])),

                  // --- AQUÍ ESTÁ LA MAGIA: BOTÓN DE IMPRIMIR POR MATERIA ---
                  IconButton(
                    icon: const Icon(Icons.print, color: Colors.orange),
                    tooltip: "Descargar Bitácora",
                    onPressed: () async {
                      final user = Provider.of<HomeMenuViewModel>(context, listen: false).currentUser;
                      if (user == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Error: No se encontró información del usuario"))
                        );
                        return;
                      }
                        await PdfGeneratorService().generarBitacora(
                          user: user,
                          materia: data['subject'] ?? "Materia",
                          profesor: data['professor'] ?? "Sin Asignar",
                          horario: data['schedule'] ?? "",
                          salon: data['salon'] ?? "",
                          academia: data['academy'] ?? "Sin Asignar",
                        );
                    },
                  )
                ]),
              );
            }),
          ],
        );
      },
    );
  }
}
