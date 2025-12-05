import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
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
                  if (vm.groupedEvidences.isEmpty)
                    const Card(child: Padding(padding: EdgeInsets.all(24.0), child: Center(child: Text("No ha subido ninguna evidencia."))))
                  else
                    _EvidencePageView(groupedEvidences: vm.groupedEvidences),
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
    return Card(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: Padding(padding: const EdgeInsets.all(16.0), child: Column(
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
    )));
  }
  
  Widget _buildInfoRow(IconData icon, String label, String value, {bool isStatus = false}) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Row(children: [
      Icon(icon, color: Colors.grey.shade600, size: 20),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: isStatus ? (value == 'EN_CURSO' ? Colors.green : Colors.orange) : Colors.black54, fontSize: 16)),
      ])),
    ]));
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

  Future<void> _launchUrl(BuildContext context, String? urlString) async {
    if (urlString == null || urlString.isEmpty) {
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay un archivo para mostrar.')));
      return;
    }
    final uri = Uri.parse(urlString);
    if (context.mounted && !await launchUrl(uri)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo abrir el enlace: $urlString')));
    }
  }
}

class _EvidencePageView extends StatefulWidget {
  final Map<String, Map<String, List<EvidenceModel>>> groupedEvidences;
  const _EvidencePageView({required this.groupedEvidences});

  @override
  State<_EvidencePageView> createState() => _EvidencePageViewState();
}

class _EvidencePageViewState extends State<_EvidencePageView> {
  final _controller = PageController(viewportFraction: 0.9);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subjects = widget.groupedEvidences.entries.toList();

    return Column(
      children: [
        SizedBox(
          height: 400,
          child: PageView.builder(
            controller: _controller,
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final subject = subjects[index].key;
              final statuses = subjects[index].value;
              return _buildSubjectCard(context, subject, statuses);
            },
          ),
        ),
        const SizedBox(height: 16),
        SmoothPageIndicator(
          controller: _controller,
          count: subjects.length,
          effect: const WormEffect(
            dotHeight: 8,
            dotWidth: 8,
            activeDotColor: AppTheme.bluePrimary
          ), 
        ),
      ],
    );
  }

  Widget _buildSubjectCard(BuildContext context, String subject, Map<String, List<EvidenceModel>> statuses) {
    final pending = statuses['pending']!;
    final approved = statuses['approved']!;
    final rejected = statuses['rejected']!;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subject, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.blueDark)),
            const Divider(height: 20),
            _buildEvidencesSubSection("En Revisión", pending),
            _buildEvidencesSubSection("Rechazadas", rejected),
            _buildEvidencesSubSection("Aprobadas", approved),
          ],
        ),
      ),
    );
  }

  Widget _buildEvidencesSubSection(String title, List<EvidenceModel> evidences) {
    if (evidences.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
          ...evidences.map((e) => _EvidenceCard(evidence: e)),
        ],
      ),
    );
  }
}


class _EvidenceCard extends StatelessWidget {
  final EvidenceModel evidence;
  const _EvidenceCard({required this.evidence});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> statusInfo = _getStatusInfo(evidence.status);
    return Card(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Icon(statusInfo['icon'], color: statusInfo['color']),
        title: Text(evidence.fileName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
        subtitle: Text("Subido: ${DateFormat.yMd().format(evidence.uploadedAt)}", style: const TextStyle(fontSize: 12)),
        trailing: Text(statusInfo['text'], style: TextStyle(color: statusInfo['color'], fontWeight: FontWeight.bold, fontSize: 12)),
        onTap: () {
          showDialog(
            context: context,
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
      default:
        return {'icon': Icons.hourglass_top, 'color': Colors.orange, 'text': 'En Revisión'};
    }
  }
}

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
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("El motivo del rechazo es obligatorio."), backgroundColor: Colors.red),
      );
      return;
    }

    final success = await vm.reviewEvidence(
      evidenceId: widget.evidence.id,
      isApproved: isApproved,
      feedback: _feedbackController.text,
    );

    if (context.mounted && success) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StudentDetailViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text("Revisar: ${widget.evidence.fileName}"),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          Expanded(child: Container(
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
            alignment: Alignment.center,
            child: _isImage
                ? InteractiveViewer(child: Image.network(widget.evidence.fileUrl, fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator())))
                : Center(child: ElevatedButton.icon(
                    icon: const Icon(Icons.open_in_new),
                    label: const Text("Abrir PDF en nueva pestaña"),
                    onPressed: () async {
                      final uri = Uri.parse(widget.evidence.fileUrl);
                      if (context.mounted && !await launchUrl(uri)) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir el enlace.')));
                      }
                    },
                  ),),
          )),
          const SizedBox(height: 16),
          if (vm.isLoading)
            const Center(child: CircularProgressIndicator())
          else
            _buildReviewActions(context),
        ]),
      ),
    );
  }

  Widget _buildReviewActions(BuildContext context) {
    return Card(elevation: 4, child: Padding(padding: const EdgeInsets.all(16.0), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text("¿La evidencia es correcta?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: ElevatedButton.icon(icon: const Icon(Icons.close), label: const Text("Rechazar"),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), onPressed: () => _showFeedbackDialog(context))),
        const SizedBox(width: 16),
        Expanded(child: ElevatedButton.icon(icon: const Icon(Icons.check), label: const Text("Aprobar"),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white), onPressed: () => _submitReview(context, true))),
      ]),
    ])));
  }

  void _showFeedbackDialog(BuildContext context) {
    showDialog(context: context, builder: (dialogContext) => AlertDialog(
      title: const Text("Motivo del Rechazo"),
      content: TextField(controller: _feedbackController, decoration: const InputDecoration(labelText: "Escribe una breve explicación...", border: OutlineInputBorder()), autofocus: true, maxLines: 3),
      actions: [
        TextButton(child: const Text("Cancelar"), onPressed: () => Navigator.of(dialogContext).pop()),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          onPressed: () {
            Navigator.of(dialogContext).pop();
            _submitReview(context, false);
          }, 
          child: const Text("Confirmar Rechazo"),
        ),
      ],
    ));
  }
}
