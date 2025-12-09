import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/responsive_container.dart';
import '../../../data/models/evidence_model.dart';
import '../../../data/models/user_model.dart';
import '../../../theme/theme.dart';
import 'upload_evidence_view.dart';

class StudentHistoryView extends StatelessWidget {
  final UserModel user;

  const StudentHistoryView({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    // CORRECCIÓN 1: El nombre de la colección debe coincidir con AuthRepository ('evidencias')
    // CORRECCIÓN 2: Esta consulta requiere un índice en Firebase.
    // Ve a tu consola de Firebase > Firestore > Índices y crea uno para:
    // Colección: evidencias
    // Campos: uid (Ascendente/Descendente), uploaded_at (Descendente)
    final query = FirebaseFirestore.instance
        .collection('evidencias') // <--- CAMBIADO DE 'evidence' A 'evidencias'
        .where('uid', isEqualTo: user.id)
        .orderBy('uploaded_at', descending: true);

    return Scaffold(
      backgroundColor: AppTheme.baseLight,
      appBar: AppBar(
        title: const Text("Historial de Evidencias"),
        elevation: 0,
      ),
      body: ResponsiveContainer(
        child: StreamBuilder<QuerySnapshot>(
          stream: query.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              // Si el error es por falta de índice, Firebase te da un link en la consola de debug
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "Error al cargar historial.\n\nSi ves un error de 'indexes', revisa la consola de depuración (Run) y haz clic en el enlace que genera Firebase para crear el índice automáticamente.\n\nDetalle: ${snapshot.error}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.history, size: 60, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text("Aún no tienes evidencias enviadas.", style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadEvidenceView())),
                      child: const Text("Subir mi primera evidencia"),
                    )
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                // Crear modelo
                final evidence = EvidenceModel.fromMap(data, docs[index].id);
                return _EvidenceHistoryCard(evidence: evidence);
              },
            );
          },
        ),
      ),
    );
  }
}

class _EvidenceHistoryCard extends StatelessWidget {
  final EvidenceModel evidence;

  const _EvidenceHistoryCard({required this.evidence});

  void _showRejectionReasons(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red),
          SizedBox(width: 10),
          Text("Motivos de Rechazo")
        ]),
        content: Text(evidence.feedback ?? "Sin motivos especificados."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cerrar"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.bluePrimary, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadEvidenceView()));
            },
            child: const Text("Corregir y Reenviar"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    IconData statusIcon;
    Color statusColor;
    String statusText;
    bool isRejected = false;

    switch (evidence.status) {
      case 'APROBADA':
        statusIcon = Icons.check_circle;
        statusColor = Colors.green;
        statusText = "Aceptada";
        break;
      case 'RECHAZADA':
        statusIcon = Icons.cancel;
        statusColor = Colors.red;
        statusText = "Rechazada";
        isRejected = true;
        break;
      default:
        statusIcon = Icons.hourglass_top;
        statusColor = Colors.orange;
        statusText = "En Revisión";
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statusColor.withAlpha(30),
            shape: BoxShape.circle,
          ),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(evidence.subject, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Archivo: ${evidence.fileName}"),
            Text("Fecha: ${DateFormat('dd/MM/yyyy').format(evidence.uploadedAt)}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
            if (isRejected)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  "Toca para ver motivos",
                  style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              )
          ],
        ),
        trailing: isRejected
            ? IconButton(
          icon: const Icon(Icons.info_outline, color: Colors.red),
          onPressed: () => _showRejectionReasons(context),
        )
            : Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
        onTap: isRejected ? () => _showRejectionReasons(context) : null,
      ),
    );
  }
}