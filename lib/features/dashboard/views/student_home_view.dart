import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Imports necesarios
import '../../../data/models/user_model.dart';
import '../../../theme/theme.dart';
import '../viewmodels/home_menu_viewmodel.dart';
import 'upload_evidence_view.dart';

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
        // ... (Tu configuración de AppBar igual que antes) ...
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.blueDark),
            onPressed: () async {
              await viewModel.logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            Text("Hola,", style: theme.textTheme.titleLarge?.copyWith(color: AppTheme.textSecondary, fontSize: 20)),
            Text(user.name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.blueDark)),

            const SizedBox(height: 30),

            // --- ESTATUS ---
            _StatusCard(status: user.status),

            const SizedBox(height: 20),

            // --- AQUÍ ESTÁ EL CAMBIO IMPORTANTE ---
            // En lugar de _TutorCard, ponemos la lista de clases
            // Usamos user.id (que es el ID del documento del alumno)
            _ClassesList(studentUid: user.id),

            const SizedBox(height: 30),

            // --- ACCIONES RÁPIDAS ---
            Text("Acciones Rápidas", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 15),

            // ... (Tu GridView de botones igual que antes) ...
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
                  icon: Icons.history,
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
// WIDGETS PRIVADOS (Ahora viven aquí)
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
        boxShadow: [
          BoxShadow(
            // Corregido: usamos .withValues en lugar de .withOpacity
            color: cardColor.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Estatus Actual",
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
              ),
              Icon(icon, color: Colors.white, size: 28),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold
            ),
          ),
          const SizedBox(height: 5),
          Text(
            desc,
            style: const TextStyle(color: Colors.white),
          ),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppTheme.baseLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_search, color: AppTheme.textSecondary),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Buscando Tutor...", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                Text("Te notificaremos cuando se asigne.", style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0,2))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: color),
            ),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          ],
        ),
      ),
    );
  }
}

class _ClassesList extends StatelessWidget {
  final String studentUid;

  const _ClassesList({required this.studentUid});

  @override
  Widget build(BuildContext context) {
    // Escuchamos en tiempo real la colección 'enrollments'
    final query = FirebaseFirestore.instance
        .collection('enrollments')
        .where('uid', isEqualTo: studentUid); // Filtramos por el ID del alumno

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Text("Error cargando horario");
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: LinearProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        // Si NO tiene materias, mostramos la tarjeta de "Buscando..."
        if (docs.isEmpty) {
          return const _WaitingCard();
        }

        // Si SÍ tiene materias, pintamos la lista
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Mis Clases y Horarios", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.blueDark)),
            const SizedBox(height: 10),

            ...docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5, offset: const Offset(0, 4))
                    ]
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(color: AppTheme.baseLight, shape: BoxShape.circle),
                      child: const Icon(Icons.book, color: AppTheme.bluePrimary),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['subject'] ?? 'Materia', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text("Prof: ${data['professor']}", style: const TextStyle(color: Colors.grey)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 14, color: AppTheme.bluePrimary),
                              const SizedBox(width: 4),
                              Text(
                                  data['schedule'] ?? '--:--',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)
                              ),
                              const SizedBox(width: 15),
                              const Icon(Icons.location_on, size: 14, color: Colors.orange),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  data['salon'] ?? 'Sin Salón',
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis, // Pone "..." si no cabe
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    )
                  ],
                ),
              );
            }), // .toList() no es necesario con el spread operator (...)
          ],
        );
      },
    );
  }
}