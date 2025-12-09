import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/enrollment_model.dart';
import '../../../data/models/evidence_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';

class StudentDetailViewModel extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthRepository _authRepo;

  bool _isLoading = true;
  String? _errorMessage;

  // --- STATE ---
  late UserModel student;
  List<EnrollmentModel> _enrollments = [];
  final Map<String, Map<String, List<EvidenceModel>>> _groupedEvidences = {};

  // --- GETTERS ---
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<EnrollmentModel> get enrollments => _enrollments;
  Map<String, Map<String, List<EvidenceModel>>> get groupedEvidences => _groupedEvidences;

  final String studentId;

  StudentDetailViewModel({
    required UserModel initialStudent,
    required this.studentId,
    required AuthRepository authRepo
  }) : student = initialStudent,
        _authRepo = authRepo {
    loadStudentData();
  }

  Future<void> loadStudentData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Recargar datos del alumno (para ver si cambió el estatus global)
      final studentDoc = await _db.collection('users').doc(studentId).get();
      if (studentDoc.exists) {
        student = UserModel.fromMap(studentDoc.data()!, studentDoc.id);
      } else {
        throw Exception("No se pudo encontrar al estudiante.");
      }

      // 2. Cargar inscripciones (Materias)
      final enrollmentsSnapshot = await _db.collection('enrollments').where('uid', isEqualTo: studentId).get();
      _enrollments = enrollmentsSnapshot.docs.map((doc) => EnrollmentModel.fromMap(doc.data(), doc.id)).toList();

      // 3. Cargar evidencias (Corregido a 'evidencias' en español)
      final evidencesSnapshot = await _db.collection('evidencias').where('uid', isEqualTo: studentId).get();

      _groupedEvidences.clear();
      for (var doc in evidencesSnapshot.docs) {
        final evidence = EvidenceModel.fromMap(doc.data(), doc.id);
        final subject = evidence.subject;

        _groupedEvidences.putIfAbsent(subject, () => {
          'pending': [],
          'approved': [],
          'rejected': [],
        });

        switch (evidence.status) {
          case 'APROBADA': _groupedEvidences[subject]!['approved']!.add(evidence); break;
          case 'RECHAZADA': _groupedEvidences[subject]!['rejected']!.add(evidence); break;
          default: _groupedEvidences[subject]!['pending']!.add(evidence); break;
        }
      }

    } catch (e) {
      _errorMessage = "Error cargando los datos del alumno: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> reviewEvidence({
    required String evidenceId,
    required bool isApproved,
    String? feedback,
  }) async {
    if (!isApproved && (feedback == null || feedback.trim().isEmpty)) {
      return "El motivo del rechazo es obligatorio.";
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepo.reviewEvidence(
          evidenceId: evidenceId,
          newStatus: isApproved ? 'APROBADA' : 'RECHAZADA',
          feedback: feedback
      );
      await loadStudentData(); // Recargar para actualizar la vista
      return null;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  Future<String?> assignSubjectGrade({
    required String enrollmentId,
    required String gradeInput,
    required bool isAccredited,
  }) async {
    final grade = double.tryParse(gradeInput);
    if (grade == null || grade < 0 || grade > 10) {
      return "Ingresa una calificación válida (0-10)";
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Llamada al repositorio para calificar la materia individual
      await _authRepo.assignSubjectGrade(
        studentId: student.id,
        enrollmentId: enrollmentId,
        finalGrade: grade,
        status: isAccredited ? 'ACREDITADO' : 'NO_ACREDITADO',
      );

      // CORRECCIÓN AQUÍ: Llamamos al método correcto para recargar
      await loadStudentData();

      return null;
    } catch (e) {
      return e.toString().replaceAll("Exception: ", "");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}