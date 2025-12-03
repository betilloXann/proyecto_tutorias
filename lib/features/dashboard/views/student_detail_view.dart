import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/models/evidence_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../theme/theme.dart';
import '../viewmodels/student_detail_viewmodel.dart';

class StudentDetailView extends StatelessWidget {
  final UserModel student;

  const StudentDetailView({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => StudentDetailViewModel(
        studentId: student.id,
        authRepo: context.read<AuthRepository>(),
      ),
      child: Scaffold(
        backgroundColor: AppTheme.baseLight,
        appBar: AppBar(title: Text(student.name)),
        body: Consumer<StudentDetailViewModel>(
          builder: (context, vm, child) {
            if (vm.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (vm.errorMessage != null) {
              return Center(child: Text(vm.errorMessage!));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStudentInfoCard(context, student),
                  const SizedBox(height: 24),
                  _buildSectionTitle("CARGA ACADÉMICA REGISTRADA"),
                  _buildEnrollmentsList(vm),
                  const SizedBox(height: 24),
                  _buildSectionTitle("EVIDENCIAS SUBIDAS"),
                  _buildEvidencesList(context, vm),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.bluePrimary));
  }

  Widget _buildStudentInfoCard(BuildContext context, UserModel student) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInfoRow(Icons.person_outline, "Nombre", student.name),
            _buildInfoRow(Icons.badge_outlined, "Boleta", student.boleta),
            _buildInfoRow(Icons.email_outlined, "Correo", student.email),
            _buildInfoRow(Icons.school_outlined, "Academia", student.academy),
            _buildInfoRow(Icons.check_circle_outline, "Estatus", student.status, isStatus: true),
            if (student.dictamenUrl != null) ...[
              const Divider(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text("Ver Dictamen"),
                  onPressed: () => _launchUrl(context, student.dictamenUrl),
                  style: OutlinedButton.styleFrom(foregroundColor: AppTheme.bluePrimary),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(IconData icon, String label, String value, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(children: [
        Icon(icon, color: Colors.grey.shade600, size: 20),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(color: isStatus ? (value == 'EN_CURSO' ? Colors.green : Colors.orange) : Colors.black54, fontSize: 16)),
        ])),
      ]),
    );
  }

  Widget _buildEnrollmentsList(StudentDetailViewModel vm) {
    if (vm.enrollments.isEmpty) {
      return const Card(child: Padding(padding: EdgeInsets.all(24.0), child: Center(child: Text("No tiene materias asignadas."))));
    }
    return Column(
      children: vm.enrollments.map((e) => Card(
        margin: const EdgeInsets.only(top: 8, bottom: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: const Icon(Icons.class_outlined, color: AppTheme.bluePrimary),
          title: Text(e.subject, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text("${e.professor}\n${e.schedule} - Salón: ${e.salon}\nAsignado: ${DateFormat.yMd().add_jm().format(e.assignedAt)}"),
          isThreeLine: true,
        ),
      )).toList(),
    );
  }

  Widget _buildEvidencesList(BuildContext context, StudentDetailViewModel vm) {
    if (vm.evidences.isEmpty) {
      return const Card(child: Padding(padding: EdgeInsets.all(24.0), child: Center(child: Text("No ha subido ninguna evidencia."))));
    }
    return Column(
      children: vm.evidences.map((evidence) => _EvidenceCard(evidence: evidence)).toList(),
    );
  }

  // FIX: Removed the launch mode to let the browser handle it (opens in new tab)
  Future<void> _launchUrl(BuildContext context, String? urlString) async {
    if (urlString == null || urlString.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay un archivo para mostrar.')));
      return;
    }
    if (!await launchUrl(Uri.parse(urlString))) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo abrir el enlace: $urlString')));
    }
  }
}

// --- Evidence Card Widget ---
class _EvidenceCard extends StatelessWidget {
  final EvidenceModel evidence;
  const _EvidenceCard({required this.evidence});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> statusInfo = _getStatusInfo(evidence.status);

    return Card(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(statusInfo['icon'], color: statusInfo['color']),
        title: Text(evidence.fileName, overflow: TextOverflow.ellipsis),
        subtitle: Text("Subido: ${DateFormat.yMd().format(evidence.uploadedAt)}"),
        trailing: Text(statusInfo['text'], style: TextStyle(color: statusInfo['color'], fontWeight: FontWeight.bold)),
        onTap: () {
          showDialog(
            context: context,
            // Use a larger dialog for better viewing
            builder: (_) => Dialog.fullscreen(
              child: ChangeNotifierProvider.value(
                value: context.read<StudentDetailViewModel>(),
                child: _ReviewScreen(evidence: evidence),
              ),
            ),
          );
        },
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'APROBADA':
        return {'icon': Icons.check_circle, 'color': Colors.green, 'text': 'Aprobada'};
      case 'RECHAZADA':
        return {'icon': Icons.cancel, 'color': Colors.red, 'text': 'Rechazada'};
      default: // EN_REVISION
        return {'icon': Icons.hourglass_top, 'color': Colors.orange, 'text': 'En Revisión'};
    }
  }
}

// --- NEW: Full-screen Review Screen (instead of small dialog) ---
class _ReviewScreen extends StatefulWidget {
  final EvidenceModel evidence;
  const _ReviewScreen({required this.evidence});

  @override
  State<_ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<_ReviewScreen> {
  final _feedbackController = TextEditingController();

  bool get _isImage {
    final fileName = widget.evidence.fileName.toLowerCase();
    return fileName.endsWith('.jpg') || fileName.endsWith('.jpeg') || fileName.endsWith('.png');
  }

  void _submitReview(BuildContext context, bool isApproved) async {
    final vm = context.read<StudentDetailViewModel>();
    
    if (!isApproved && _feedbackController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("El motivo del rechazo es obligatorio."), backgroundColor: Colors.red),
      );
      return;
    }

    final success = await vm.reviewEvidence(
      evidenceId: widget.evidence.id,
      isApproved: isApproved,
      feedback: _feedbackController.text,
    );

    if (mounted && success) {
      Navigator.of(context).pop(); // Close the screen
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StudentDetailViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text("Revisar: ${widget.evidence.fileName}"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- Viewer ---
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: _isImage
                    // If it's an image, display it
                    ? InteractiveViewer(
                        child: Image.network(
                          widget.evidence.fileUrl,
                          fit: BoxFit.contain,
                           loadingBuilder: (context, child, progress) {
                            return progress == null ? child : const Center(child: CircularProgressIndicator());
                          },
                        ),
                      )
                    // If it's not an image (PDF), show a button
                    : Center(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.open_in_new),
                          label: const Text("Abrir PDF en nueva pestaña"),
                          onPressed: () async {
                            if (!await launchUrl(Uri.parse(widget.evidence.fileUrl))) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir el enlace.')));
                            }
                          },
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // --- Review Actions ---
            if (vm.isLoading)
              const Center(child: CircularProgressIndicator())
            else
              _buildReviewActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewActions(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("¿La evidencia es correcta?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.close),
                    label: const Text("Rechazar"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                    onPressed: () => _showFeedbackDialog(context),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text("Aprobar"),
                     style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    onPressed: () => _submitReview(context, true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Dialog to get feedback for rejection ---
  void _showFeedbackDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Motivo del Rechazo"),
          content: TextField(
            controller: _feedbackController,
            decoration: const InputDecoration(labelText: "Escribe una breve explicación...", border: OutlineInputBorder()),
            autofocus: true,
            maxLines: 3,
          ),
          actions: [
            TextButton(child: const Text("Cancelar"), onPressed: () => Navigator.of(dialogContext).pop()),
            ElevatedButton(
              child: const Text("Confirmar Rechazo"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close feedback dialog
                _submitReview(context, false); // Submit with the feedback
              },
            ),
          ],
        );
      },
    );
  }
}
