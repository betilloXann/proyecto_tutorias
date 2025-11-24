import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Importamos lo necesario para traer los datos
import '../../../data/repositories/auth_repository.dart';
import '../../../data/models/user_model.dart';

class HomeMenuView extends StatelessWidget {
  const HomeMenuView({super.key});

  // Función para cerrar sesión
  void _logout(BuildContext context) async {
    await context.read<AuthRepository>().signOut();
    if (context.mounted) {
      // Navegar al login y borrar historial
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authRepo = context.read<AuthRepository>();

    return Scaffold(
      backgroundColor: const Color(0xFFE6EEF8), // Tu color de fondo base
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Quitamos el botón de atrás (automático) y ponemos el LOGOUT
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout, color: Color(0xFF2F5A93)),
            tooltip: "Cerrar Sesión",
          )
        ],
      ),

      // FutureBuilder: Espera a que bajen los datos de Firebase
      body: FutureBuilder<UserModel?>(
        future: authRepo.getCurrentUserData(),
        builder: (context, snapshot) {

          // 1. Cargando...
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Error o No hay datos
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text("Error cargando perfil: ${snapshot.error}"));
          }

          // 3. ¡Tenemos datos!
          final user = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- HEADER: SALUDO ---
                Text(
                  "Hola,",
                  style: theme.textTheme.titleLarge?.copyWith(color: Colors.grey),
                ),
                Text(
                  user.name, // NOMBRE REAL DE FIREBASE
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2F5A93),
                  ),
                ),

                const SizedBox(height: 30),

                // --- TARJETA DE ESTATUS (SEMÁFORO) ---
                _StatusCard(status: user.status),

                const SizedBox(height: 20),

                // --- TARJETA DEL TUTOR ---
                // Solo la mostramos si ya no está pendiente
                if (user.status != 'PENDIENTE_ASIGNACION' && user.status != 'PRE_REGISTRO')
                  _TutorCard(user: user)
                else
                  const _WaitingCard(),

                const SizedBox(height: 30),

                // --- ACCIONES RÁPIDAS (GRID) ---
                Text(
                  "Acciones Rápidas",
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),

                GridView.count(
                  shrinkWrap: true, // Importante para que funcione dentro de Column
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _ActionItem(
                      icon: Icons.upload_file,
                      label: "Subir Evidencia",
                      color: Colors.blue,
                      onTap: () {
                        // TODO: Navegar a pantalla de subir bitácora
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Próximamente: Subir Evidencia"))
                        );
                      },
                    ),
                    _ActionItem(
                      icon: Icons.history,
                      label: "Historial",
                      color: Colors.purple,
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// --- WIDGET 1: LA TARJETA DEL SEMÁFORO ---
class _StatusCard extends StatelessWidget {
  final String status;
  const _StatusCard({required this.status});

  @override
  Widget build(BuildContext context) {
    Color cardColor;
    String title;
    String desc;
    IconData icon;

    // Lógica del Semáforo según la Tesis
    switch (status) {
      case 'PENDIENTE_ASIGNACION':
        cardColor = Colors.orange;
        title = "Asignación Pendiente";
        desc = "Estamos validando tu dictamen y asignando un tutor.";
        icon = Icons.hourglass_top;
        break;
      case 'EN_CURSO':
        cardColor = Colors.blue;
        title = "Tutoría En Curso";
        desc = "Tienes un tutor asignado. Recuerda subir tus evidencias.";
        icon = Icons.school;
        break;
      case 'ACREDITADO':
        cardColor = Colors.green;
        title = "¡Acreditado!";
        desc = "Felicidades, has completado tu recursamiento.";
        icon = Icons.check_circle;
        break;
      default:
        cardColor = Colors.grey;
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

// --- WIDGET 2: CUANDO AÚN NO HAY TUTOR ---
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
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_search, color: Colors.grey),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Buscando Tutor...", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("Te notificaremos cuando se asigne.", style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// --- WIDGET 3: TARJETA DEL TUTOR ASIGNADO (Mockup por ahora) ---
class _TutorCard extends StatelessWidget {
  final UserModel user;
  const _TutorCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0,5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Tu Tutor Asignado", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 10),
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFE6EEF8),
                child: Icon(Icons.person, color: Color(0xFF2F5A93)),
              ),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  // TODO: Estos datos vendrán de Firebase cuando hagamos la asignación
                  Text("Prof. Pendiente", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text("Materia: Pendiente", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              )
            ],
          )
        ],
      ),
    );
  }
}

// --- WIDGET 4: BOTONES DE ACCIÓN ---
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
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}