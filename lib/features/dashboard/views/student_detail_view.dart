import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:universal_html/html.dart' as html;

import '../../../core/widgets/responsive_container.dart';
import '../../../data/models/enrollment_model.dart';
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

  String _getInitials(String text) {
    if (text.isEmpty) return "X";
    List<String> words = text.trim().split(' ');
    String initials = "";
    for (var word in words) {
      if (word.isNotEmpty) initials += word[0].toUpperCase();
    }
    return initials.length > 3 ? initials.substring(0, 3) : initials;
  }

  String _generateFileName({required String docType, String subjectName = "General"}) {
    final initialsName = _getInitials(widget.student.name);
    final boleta = widget.student.boleta;
    final initialsSubject = _getInitials(subjectName);

    return "${initialsName}_${boleta}_${initialsSubject}_$docType.pdf";
  }

  Future<void> _downloadAndOpenFile(String? urlString, String fileName) async {
    if (urlString == null || urlString.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay archivo disponible.')));
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Preparando descarga de $fileName...')));

      if (kIsWeb) {
        final response = await Dio().get(urlString, options: Options(responseType: ResponseType.bytes));
        final blob = html.Blob([response.data]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        
        // Directamente llamamos a click() en la instancia del AnchorElement sin usar una variable adicional
        html.AnchorElement(href: url)
          ..setAttribute("download", fileName)
          ..click();
        
        html.Url.revokeObjectUrl(url);
        return;
      }

      final dir = await getApplicationDocumentsDirectory();
      final savePath = "${dir.path}/$fileName";

      await Dio().download(urlString, savePath);

      final result = await OpenFilex.open(savePath);
      if (result.type != ResultType.done) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Archivo guardado, pero no se pudo abrir automáticamente: ${result.message}')));
      }

    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al descargar: $e')));
    }
  }

  void _showSubjectGradeDialog(BuildContext context, EnrollmentModel enrollment) {
    final vm = context.read<StudentDetailViewModel>();
    showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: vm,
        child: _SubjectGradeDialog(enrollment: enrollment),
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
        body: ResponsiveContainer(
          child: Consumer<StudentDetailViewModel>(
            builder: (context, vm, child) {
              if (vm.isLoading) return const Center(child: CircularProgressIndicator());
              if (vm.errorMessage != null) return Center(child: Text(vm.errorMessage!));

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStudentInfoCard(context, vm.student),
                    const SizedBox(height: 24),
                    _buildSectionTitle("MATERIAS POR CURSAR"), // <-- NUEVA SECCIÓN
                    _buildSubjectsToTake(vm), // <-- NUEVO WIDGET
                    const SizedBox(height: 24),
                    _buildSectionTitle("CARGA ACADÉMICA REGISTRADA"),
                    _buildEnrollmentsList(vm, context),
                    const SizedBox(height: 24),
                    _buildSectionTitle("EVIDENCIAS SUBIDAS"),
                    if (vm.groupedEvidences.isEmpty)
                      const Card(child: Padding(padding: EdgeInsets.all(24.0), child: Center(child: Text("No ha subido ninguna evidencia."))))
                    else
                      _EvidencePageView(
                        groupedEvidences: vm.groupedEvidences,
                        studentName: widget.student.name,
                        studentBoleta: widget.student.boleta,
                        onDownload: _downloadAndOpenFile,
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.bluePrimary));
  }

  Widget _buildStudentInfoCard(BuildContext context, UserModel student) {
    final bool isGraded = student.finalGrade != null;

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
              _buildInfoRow(Icons.star_border, "Promedio Final", student.finalGrade.toString()),

            const Divider(height: 20),

            if (student.dictamenUrl != null) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                  label: const Text("Descargar Dictamen"),
                  onPressed: () {
                    final name = _generateFileName(docType: "Dictamen", subjectName: "General");
                    _downloadAndOpenFile(student.dictamenUrl, name);
                  },
                  style: OutlinedButton.styleFrom(foregroundColor: AppTheme.bluePrimary),
                ),
              ),
            ],
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

  // --- WIDGET PARA MATERIAS POR CURSAR (NUEVO) ---
  Widget _buildSubjectsToTake(StudentDetailViewModel vm) {
    if (vm.subjectsToTakeStatus.isEmpty) {
      return const Card(child: Padding(padding: EdgeInsets.all(24.0), child: Center(child: Text("No tiene materias por cursar definidas."))));
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: vm.subjectsToTakeStatus.length,
        separatorBuilder: (_, _) => const Divider(height: 1, indent: 16, endIndent: 16),
        itemBuilder: (context, index) {
          final subject = vm.subjectsToTakeStatus.keys.elementAt(index);
          final status = vm.subjectsToTakeStatus.values.elementAt(index);
          final statusInfo = _getStatusInfoForSubject(status);

          return ListTile(
            title: Text(subject),
            trailing: Chip(
              label: Text(statusInfo.text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              backgroundColor: statusInfo.color,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          );
        },
      ),
    );
  }

  ({String text, Color color}) _getStatusInfoForSubject(String status) {
    switch (status) {
      case 'ACREDITADO': return (text: 'Acreditado', color: Colors.green);
      case 'NO_ACREDITADO': return (text: 'No Acreditado', color: Colors.red);
      case 'EN_CURSO': return (text: 'En Curso', color: AppTheme.bluePrimary);
      default: return (text: 'Pendiente', color: Colors.orange);
    }
  }

  Widget _buildEnrollmentsList(StudentDetailViewModel vm, BuildContext context) {
    if (vm.enrollments.isEmpty) {
      return const Card(child: Padding(padding: EdgeInsets.all(24.0), child: Center(child: Text("No tiene materias asignadas."))));
    }
    return Column(
        children: vm.enrollments.map((e) {
          final bool isGraded = e.status == 'ACREDITADO' || e.status == 'NO_ACREDITADO';
          Color statusColor = Colors.grey;
          if (e.status == 'ACREDITADO') statusColor = Colors.green;
          if (e.status == 'NO_ACREDITADO') statusColor = Colors.red;
          if (e.status == 'EN_CURSO') statusColor = AppTheme.bluePrimary;

          return Card(
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: statusColor.withValues(alpha:0.5))),
            child: ListTile(
              leading: Icon(Icons.class_outlined, color: statusColor),
              title: Text(e.subject, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${e.professor} (${e.schedule})"),
                  if (isGraded)
                    Text("Calificación: ${e.finalGrade ?? '-'}", style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                  if (!isGraded)
                    const Text("Estatus: En Curso", style: TextStyle(fontSize: 12)),
                ],
              ),
              trailing: IconButton(
                icon: Icon(isGraded ? Icons.edit : Icons.grading, color: AppTheme.blueDark),
                tooltip: "Calificar esta materia",
                onPressed: () => _showSubjectGradeDialog(context, e),
              ),
            ),
          );
        }).toList()
    );
  }
}

// ... (El resto de la vista se mantiene igual)





class _SubjectGradeDialog extends StatefulWidget {
  final EnrollmentModel enrollment;
  const _SubjectGradeDialog({required this.enrollment});

  @override
  State<_SubjectGradeDialog> createState() => _SubjectGradeDialogState();
}

class _SubjectGradeDialogState extends State<_SubjectGradeDialog> {
  late final TextEditingController _gradeController;

  bool _isAccredited = false;
  String _statusMessage = "";
  Color _statusColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    _gradeController = TextEditingController(text: widget.enrollment.finalGrade?.toString() ?? '');
    _updateStatus(_gradeController.text);
  }

  @override
  void dispose() {
    _gradeController.dispose();
    super.dispose();
  }

  void _updateStatus(String value) {
    final grade = double.tryParse(value);
    setState(() {
      if (grade == null) {
        _isAccredited = false;
        _statusMessage = "Ingresa la calificación";
        _statusColor = Colors.grey;
      } else if (grade > 5) {
        _isAccredited = true;
        _statusMessage = "¡Felicidades! Alumno Acreditado";
        _statusColor = Colors.green;
      } else {
        _isAccredited = false;
        _statusMessage = "Alumno Reprobado";
        _statusColor = Colors.red;
      }
    });
  }

  void _submit() async {
    final vm = context.read<StudentDetailViewModel>();

    final error = await vm.assignSubjectGrade(
        enrollmentId: widget.enrollment.id,
        gradeInput: _gradeController.text,
        isAccredited: _isAccredited
    );

    if (!mounted) return;

    if (error == null) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Calificar: ${widget.enrollment.subject}", style: const TextStyle(fontSize: 16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _gradeController,
            decoration: const InputDecoration(labelText: "Calificación (0-10)", border: OutlineInputBorder()),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: _updateStatus,
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
                color: _statusColor.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _statusColor.withValues(alpha:0.3))
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isAccredited ? Icons.check_circle : (_statusMessage == "Ingresa la calificación" ? Icons.edit : Icons.cancel),
                  color: _statusColor,
                ),
                const SizedBox(width: 8),
                Text(
                  _statusMessage,
                  style: TextStyle(
                      color: _statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14
                  ),
                ),
              ],
            ),
          )
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Cancelar")),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(backgroundColor: _statusColor),
          child: const Text("Guardar", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

class _EvidencePageView extends StatefulWidget {
  final Map<String, Map<String, List<EvidenceModel>>> groupedEvidences;
  final String studentName;
  final String studentBoleta;
  final Function(String?, String) onDownload;

  const _EvidencePageView({
    required this.groupedEvidences,
    required this.studentName,
    required this.studentBoleta,
    required this.onDownload,
  });

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
              Align(alignment: Alignment.centerLeft, child: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: () => _controller.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut))),
              Align(alignment: Alignment.centerRight, child: IconButton(icon: const Icon(Icons.arrow_forward_ios_rounded), onPressed: () => _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut))),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SmoothPageIndicator(controller: _controller, count: subjects.length, effect: const WormEffect(dotHeight: 8, dotWidth: 8, activeDotColor: AppTheme.bluePrimary)),
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
            _buildEvidencesSubSection("En Revisión", statuses['pending']!, subject),
            _buildEvidencesSubSection("Rechazadas", statuses['rejected']!, subject),
            _buildEvidencesSubSection("Aprobadas", statuses['approved']!, subject),
          ],
        ),
      ),
    );
  }

  Widget _buildEvidencesSubSection(String title, List<EvidenceModel> evidences, String subjectName) {
    if (evidences.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
          ...evidences.map((e) => _EvidenceCard(
            evidence: e,
            studentName: widget.studentName,
            studentBoleta: widget.studentBoleta,
            subjectName: subjectName,
            onDownload: widget.onDownload,
          )),
        ],
      ),
    );
  }
}

class _EvidenceCard extends StatelessWidget {
  final EvidenceModel evidence;
  final String studentName;
  final String studentBoleta;
  final String subjectName;
  final Function(String?, String) onDownload;

  const _EvidenceCard({
    required this.evidence,
    required this.studentName,
    required this.studentBoleta,
    required this.subjectName,
    required this.onDownload,
  });

  String _getInitials(String text) {
    if (text.isEmpty) return "X";
    List<String> words = text.trim().split(' ');
    String initials = "";
    for (var word in words) {
      if (word.isNotEmpty) initials += word[0].toUpperCase();
    }
    return initials.length > 3 ? initials.substring(0, 3) : initials;
  }

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
          final vm = context.read<StudentDetailViewModel>();

          final initialsName = _getInitials(studentName);
          final initialsSubj = _getInitials(subjectName);
          final fileName = "${initialsName}_${studentBoleta}_${initialsSubj}_Reporte.pdf";

          showDialog(
            context: context,
            builder: (_) => Dialog.fullscreen(
              child: ChangeNotifierProvider.value(
                value: vm,
                child: _ReviewScreen(
                  evidence: evidence,
                  fileName: fileName,
                  onDownload: onDownload,
                ),
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
  final String fileName;
  final Function(String?, String) onDownload;

  const _ReviewScreen({required this.evidence, required this.fileName, required this.onDownload});

  @override
  State<_ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<_ReviewScreen> {

  bool get _isImage {
    final fileName = widget.evidence.fileName.toLowerCase();
    return fileName.endsWith('.jpg') || fileName.endsWith('.jpeg') || fileName.endsWith('.png');
  }

  void _submitReview(bool isApproved, {String? feedback}) async {
    final vm = context.read<StudentDetailViewModel>();
    final error = await vm.reviewEvidence(
      evidenceId: widget.evidence.id,
      isApproved: isApproved,
      feedback: feedback ?? '',
    );

    if (!mounted) return;

    if (error == null) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
    }
  }

  void _showFeedbackDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => const _RejectionDialog(),
    );

    if (result != null && mounted) {
      _submitReview(false, feedback: result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StudentDetailViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text("Revisar: ${widget.evidence.fileName}"),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: "Descargar con nombre oficial",
            onPressed: () => widget.onDownload(widget.evidence.fileUrl, widget.fileName),
          )
        ],
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
                : Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.picture_as_pdf, size: 60, color: Colors.red),
                const SizedBox(height: 16),
                Text(widget.fileName, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.file_download),
                  label: const Text("Descargar Archivo"),
                  onPressed: () => widget.onDownload(widget.evidence.fileUrl, widget.fileName),
                ),
              ],
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

class _RejectionDialog extends StatefulWidget {
  const _RejectionDialog();

  @override
  State<_RejectionDialog> createState() => _RejectionDialogState();
}

class _RejectionDialogState extends State<_RejectionDialog> {
  final TextEditingController _commentCtrl = TextEditingController();
  final List<String> _reasons = [
    "Archivo ilegible o dañado",
    "No corresponde al mes reportado",
    "Información incompleta",
    "Formato no oficial",
    "Evidencia duplicada",
  ];
  final Set<String> _selectedReasons = {};

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final List<String> finalReasons = _selectedReasons.toList();
    if (_commentCtrl.text.trim().isNotEmpty) {
      finalReasons.add("Nota: ${_commentCtrl.text.trim()}");
    }

    if (finalReasons.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Selecciona al menos un motivo")));
      return;
    }
    Navigator.of(context).pop(finalReasons.join(". "));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Motivo del Rechazo", style: TextStyle(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Selecciona los motivos:", style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8.0, runSpacing: 4.0,
              children: _reasons.map((reason) {
                final isSelected = _selectedReasons.contains(reason);
                return FilterChip(
                  label: Text(reason),
                  selected: isSelected,
                  selectedColor: Colors.red.shade100,
                  checkmarkColor: Colors.red,
                  labelStyle: TextStyle(color: isSelected ? Colors.red.shade900 : Colors.black87, fontSize: 12),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) { _selectedReasons.add(reason); } else { _selectedReasons.remove(reason); }
                    });
                  },
                );
              }).toList(),
            ),
            const Divider(height: 24),
            TextField(
              controller: _commentCtrl,
              decoration: const InputDecoration(labelText: "Comentario adicional (Opcional)", border: OutlineInputBorder(), isDense: true),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(child: const Text("Cancelar"), onPressed: () => Navigator.of(context).pop()),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          onPressed: _submit,
          child: const Text("Confirmar Rechazo"),
        ),
      ],
    );
  }
}