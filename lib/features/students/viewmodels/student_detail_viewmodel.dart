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
  Map<String, String> _subjectsToTakeStatus = {}; // <-- NUEVO

  // --- GETTERS ---
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<EnrollmentModel> get enrollments => _enrollments;
  Map<String, Map<String, List<EvidenceModel>>> get groupedEvidences => _groupedEvidences;
  Map<String, String> get subjectsToTakeStatus => _subjectsToTakeStatus; // <-- NUEVO

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
      final currentUser = await _authRepo.getCurrentUserData();
      final userAcademies = currentUser?.academies ?? [];

      final studentDoc = await _db.collection('users').doc(studentId).get();
      if (studentDoc.exists) {
        student = UserModel.fromMap(studentDoc.data()!, studentDoc.id);
      } else {
        throw Exception("No se pudo encontrar al estudiante.");
      }

      // Cargar todas las inscripciones del alumno para la lógica de materias
      final allEnrollmentsSnapshot = await _db.collection('enrollments').where('uid', isEqualTo: studentId).get();
      final allEnrollments = allEnrollmentsSnapshot.docs.map((doc) => EnrollmentModel.fromMap(doc.data(), doc.id)).toList();
      final enrolledSubjectsMap = { for (var e in allEnrollments) e.subject.trim().toLowerCase() : e.status };

      // --- LÓGICA DE MATERIAS POR CURSAR (NUEVO) ---
      List<String> relevantSubjectsToTake = [];
      if (currentUser?.role == 'jefe_academia') {
        if (userAcademies.isNotEmpty) {
          final academySubjectsSnapshot = await _db.collection('subjects').where('academy', whereIn: userAcademies).get();
          final academySubjectNames = academySubjectsSnapshot.docs.map((d) => (d.data()['name'] as String).trim().toLowerCase()).toSet();
          relevantSubjectsToTake = student.subjectsToTake.where((s) => academySubjectNames.contains(s.trim().toLowerCase())).toList();
        }
      } else {
        relevantSubjectsToTake = student.subjectsToTake;
      }

      _subjectsToTakeStatus = {};
      for (String subjectName in relevantSubjectsToTake) {
        final subjectNameLower = subjectName.trim().toLowerCase();
        if (enrolledSubjectsMap.containsKey(subjectNameLower)) {
          _subjectsToTakeStatus[subjectName] = enrolledSubjectsMap[subjectNameLower]!;
        } else {
          _subjectsToTakeStatus[subjectName] = 'PENDIENTE';
        }
      }
      // --- FIN LÓGICA DE MATERIAS POR CURSAR ---

      // Filtrar inscripciones y evidencias solo si es jefe de academia
      if (currentUser?.role == 'jefe_academia') {
        _enrollments = allEnrollments.where((e) => userAcademies.contains(e.academy)).toList();
        final academySubjectNames = _enrollments.map((e) => e.subject.trim().toLowerCase()).toSet();

        final evidencesSnapshot = await _db.collection('evidencias').where('uid', isEqualTo: studentId).get();
        _groupedEvidences.clear();
        for (var doc in evidencesSnapshot.docs) {
          final evidence = EvidenceModel.fromMap(doc.data(), doc.id);
          if (academySubjectNames.contains(evidence.subject.trim().toLowerCase())) {
            final subject = evidence.subject;
            _groupedEvidences.putIfAbsent(subject, () => {'pending': [], 'approved': [], 'rejected': []});
            switch (evidence.status) {
              case 'APROBADA': _groupedEvidences[subject]!['approved']!.add(evidence); break;
              case 'RECHAZADA': _groupedEvidences[subject]!['rejected']!.add(evidence); break;
              default: _groupedEvidences[subject]!['pending']!.add(evidence); break;
            }
          }
        }
      } else {
        // Para admin/tutorias, mostrar todo
        _enrollments = allEnrollments;
        final evidencesSnapshot = await _db.collection('evidencias').where('uid', isEqualTo: studentId).get();
         _groupedEvidences.clear();
          for (var doc in evidencesSnapshot.docs) {
            final evidence = EvidenceModel.fromMap(doc.data(), doc.id);
            final subject = evidence.subject;
            _groupedEvidences.putIfAbsent(subject, () => {'pending': [], 'approved': [], 'rejected': []});
             switch (evidence.status) {
                case 'APROBADA': _groupedEvidences[subject]!['approved']!.add(evidence); break;
                case 'RECHAZADA': _groupedEvidences[subject]!['rejected']!.add(evidence); break;
                default: _groupedEvidences[subject]!['pending']!.add(evidence); break;
              }
          }
      }

    } catch (e) {
      _errorMessage = "Error cargando los datos del alumno: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> reviewEvidence({ required String evidenceId, required bool isApproved, String? feedback }) async {
    if (!isApproved && (feedback == null || feedback.trim().isEmpty)) {
      return "El motivo del rechazo es obligatorio.";
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authRepo.reviewEvidence(evidenceId: evidenceId, newStatus: isApproved ? 'APROBADA' : 'RECHAZADA', feedback: feedback);
      await loadStudentData();
      return null;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  Future<String?> assignSubjectGrade({ required String enrollmentId, required String gradeInput, required bool isAccredited }) async {
    final grade = double.tryParse(gradeInput);
    if (grade == null || grade < 0 || grade > 10) {
      return "Ingresa una calificación válida (0-10)";
    }

    final enrollment = _enrollments.firstWhere(
      (e) => e.id == enrollmentId, 
      orElse: () => throw Exception("No se encontró la información de la materia")
    );
    
    _isLoading = true;
    notifyListeners();
    try {
await _authRepo.assignSubjectGrade(
        studentId: student.id,
        enrollmentId: enrollmentId,
        finalGrade: grade,
        status: isAccredited ? 'ACREDITADO' : 'NO_ACREDITADO',
        // --- Nuevos datos para el Word ---
        studentName: student.name,
        boleta: student.boleta,
        subjectName: enrollment.subject,
        professorName: enrollment.professor.isNotEmpty ? enrollment.professor : "Sin Asignar",
      );
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
