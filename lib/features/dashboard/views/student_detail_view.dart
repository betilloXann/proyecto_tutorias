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

class StudentDetailView extends StatefulWidget {
  final UserModel student;

  const StudentDetailView({super.key, required this.student});

  @override
  State<StudentDetailView> createState() => _StudentDetailViewState();
}

class _StudentDetailViewState extends State<StudentDetailView> {
  
  // --- UI ACTIONS (Solo acciones de UI, sin lógica de negocio) ---
  
  Future<void> _launchUrl(String? urlString) async {
    if (urlString == null || urlString.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay un archivo para mostrar.')));
      }
      return;
    }
    
    final uri = Uri.parse(urlString);
    final launched = await launchUrl(uri);
    
    if (!mounted) return;
    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo abrir el enlace: $urlString')));
    }
  }

  void _showFinalGradeDialog(BuildContext context) {
    // Pasamos el contexto del provider padre al diálogo
    final vm = context.read<StudentDetailViewModel>();
    showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: vm,
        child: _FinalGradeDialog(student: vm.student),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => StudentDetailViewModel(
        initialStudent: widget.student,
        studentId: widget.student.id,
        authRepo: context.read<AuthRepository>(),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Consumer<StudentDetailViewModel>(
            builder: (_, vm, _) => Text(vm.student.name),
          ),
        ),
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
                  _buildStudentInfoCard(context, vm.student),
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
    final bool isGraded = student.finalGrade != null;

    final bool canAssignGrade = student.status == 'EN_CURSO';

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
            _buildInfoRow(Icons.school_outlined, "Academias", student.academies.join(", ")),
            _buildInfoRow(Icons.history_toggle_off, "Estatus", student.status, isStatus: true),
            if (isGraded)
              _buildInfoRow(Icons.star_border, "Calificación Final", student.finalGrade.toString()),
            
            const Divider(height: 20),

            if (student.dictamenUrl != null) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                  label: const Text("Ver Dictamen"),
                  onPressed: () => _launchUrl(student.dictamenUrl),
                  style: OutlinedButton.styleFrom(foregroundColor: AppTheme.bluePrimary),
                ),
              ),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.grading_outlined, size: 18),
                label: Text(isGraded ? "Editar Calificación Final" : "Asignar Calificación Final"),
                onPressed: canAssignGrade ? () => _showFinalGradeDialog(context) : null,

                style: ElevatedButton.styleFrom(
                    backgroundColor: isGraded ? Colors.blueGrey : AppTheme.blueDark,
                    foregroundColor: Colors.white
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool isStatus = false}) {
    Color statusColor = Colors.orange;
    IconData statusIcon = icon;

    if (isStatus) {
      if (value == 'ACREDITADO') {
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
      } else if (value == 'NO_ACREDITADO') {
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
      } else if (value == 'EN_CURSO'){
        statusIcon = Icons.hourglass_top;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(children: [
        Icon(statusIcon, color: isStatus ? statusColor : Colors.grey.shade600, size: 20),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(
            color: isStatus ? statusColor : Colors.black54,
            fontSize: 16,
            fontWeight: isStatus ? FontWeight.bold : FontWeight.normal
          )),
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
}

// --- SUB-WIDGETS Y DIALOGS ---

class _FinalGradeDialog extends StatefulWidget {
  final UserModel student;
  const _FinalGradeDialog({required this.student});

  @override
  State<_FinalGradeDialog> createState() => _FinalGradeDialogState();
}

class _FinalGradeDialogState extends State<_FinalGradeDialog> {
  late final TextEditingController _gradeController;
  late bool _isAccredited;

  @override
  void initState() {
    super.initState();
    _gradeController = TextEditingController(text: widget.student.finalGrade?.toString() ?? '');
    _isAccredited = widget.student.status == 'ACREDITADO';
  }

  @override
  void dispose() {
    _gradeController.dispose();
    super.dispose();
  }

  void _submit() async {
    final vm = context.read<StudentDetailViewModel>();
    
    // MVVM: Enviamos el input crudo (String) y el booleano al VM.
    final error = await vm.assignFinalGrade(
      gradeInput: _gradeController.text, 
      isAccredited: _isAccredited
    );

    if (!mounted) return;

    if (error == null) {
      // Éxito: Cerrar diálogo
      Navigator.of(context).pop();
    } else {
      // Error: Mostrar feedback visual (responsabilidad de la Vista)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Asignar Calificación Final"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _gradeController,
            decoration: const InputDecoration(labelText: "Calificación (0-10)", border: OutlineInputBorder()),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text(_isAccredited ? "ACREDITADO" : "NO ACREDITADO", style: TextStyle(color: _isAccredited ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
            value: _isAccredited,
            onChanged: (value) => setState(() => _isAccredited = value),
            activeTrackColor: Colors.green,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Cancelar")),
        ElevatedButton(
          onPressed: _submit, // Llamamos a la función local limpia
          child: const Text("Guardar"),
        ),
      ],
    );
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
          child: Stack(
            alignment: Alignment.center,
            children: [
              PageView.builder(
                controller: _controller,
                itemCount: subjects.length,
                itemBuilder: (context, index) {
                  return _buildSubjectCard(context, subjects[index].key, subjects[index].value);
                },
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () => _controller.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.arrow_forward_ios_rounded),
                  onPressed: () => _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SmoothPageIndicator(
          controller: _controller,
          count: subjects.length,
          effect: const WormEffect(dotHeight: 8, dotWidth: 8, activeDotColor: AppTheme.bluePrimary), 
        ),
      ],
    );
  }

  Widget _buildSubjectCard(BuildContext context, String subject, Map<String, List<EvidenceModel>> statuses) {
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
            _buildEvidencesSubSection("En Revisión", statuses['pending']!),
            _buildEvidencesSubSection("Rechazadas", statuses['rejected']!),
            _buildEvidencesSubSection("Aprobadas", statuses['approved']!),
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
          // Obtener VM antes de abrir diálogo
          final vm = context.read<StudentDetailViewModel>();
          showDialog(
            context: context,
            builder: (_) => Dialog.fullscreen(
              child: ChangeNotifierProvider.value(
                value: vm,
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
      case 'APROBADA': return {'icon': Icons.check_circle, 'color': Colors.green, 'text': 'Aprobada'};
      case 'RECHAZADA': return {'icon': Icons.cancel, 'color': Colors.red, 'text': 'Rechazada'};
      default: return {'icon': Icons.hourglass_top, 'color': Colors.orange, 'text': 'En Revisión'};
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

  Future<void> _launchUrl() async {
      final uri = Uri.parse(widget.evidence.fileUrl);
      final launched = await launchUrl(uri);
      
      if (!mounted) return;
      if (!launched) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir el enlace.')));
      }
  }

  void _submitReview(bool isApproved) async {
    final vm = context.read<StudentDetailViewModel>();
    
    // MVVM: Le pasamos los datos al VM. El VM decide si son válidos.
    final error = await vm.reviewEvidence(
      evidenceId: widget.evidence.id,
      isApproved: isApproved,
      feedback: _feedbackController.text,
    );

    if (!mounted) return;

    if (error == null) {
      Navigator.of(context).pop();
    } else {
      // La vista se encarga de mostrar el error que el VM reportó
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  void _showFeedbackDialog() {
    showDialog(context: context, builder: (dialogContext) => AlertDialog(
      title: const Text("Motivo del Rechazo"),
      content: TextField(controller: _feedbackController, decoration: const InputDecoration(labelText: "Escribe una breve explicación...", border: OutlineInputBorder()), autofocus: true, maxLines: 3),
      actions: [
        TextButton(child: const Text("Cancelar"), onPressed: () => Navigator.of(dialogContext).pop()),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          onPressed: () {
            Navigator.of(dialogContext).pop();
            _submitReview(false);
          }, 
          child: const Text("Confirmar Rechazo"),
        ),
      ],
    ));
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
                    onPressed: _launchUrl,
                  ),),
          )),
          const SizedBox(height: 16),
          if (vm.isLoading)
            const Center(child: CircularProgressIndicator())
          else
            _buildReviewActions(),
        ]),
      ),
    );
  }

  Widget _buildReviewActions() {
    return Card(elevation: 4, child: Padding(padding: const EdgeInsets.all(16.0), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text("¿La evidencia es correcta?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: ElevatedButton.icon(icon: const Icon(Icons.close), label: const Text("Rechazar"),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), onPressed: _showFeedbackDialog)),
        const SizedBox(width: 16),
        Expanded(child: ElevatedButton.icon(icon: const Icon(Icons.check), label: const Text("Aprobar"),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white), onPressed: () => _submitReview(true))),
      ]),
    ])));
  }
}