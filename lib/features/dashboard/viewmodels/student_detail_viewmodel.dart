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
      // 0. Obtener usuario actual y sus academias
      final currentUser = await _authRepo.getCurrentUserData();
      // SI EL USUARIO NO TIENE ACADEMIAS, SE TRATARÁ COMO LISTA VACÍA, NO LANZARÁ ERROR
      final userAcademies = currentUser?.academies ?? [];

      // 1. Recargar datos del alumno
      final studentDoc = await _db.collection('users').doc(studentId).get();
      if (studentDoc.exists) {
        student = UserModel.fromMap(studentDoc.data()!, studentDoc.id);
      } else {
        throw Exception("No se pudo encontrar al estudiante.");
      }

      // Si el usuario no tiene academias, no hay nada que mostrar.
      if (userAcademies.isEmpty) {
        _enrollments = [];
        _groupedEvidences.clear();
        _isLoading = false;
        notifyListeners();
        return;
      }

      // 2. Cargar inscripciones (Materias) FILTRADAS por las academias del usuario
      final enrollmentsSnapshot = await _db
          .collection('enrollments')
          .where('uid', isEqualTo: studentId)
          .where('academy', whereIn: userAcademies)
          .get();
      _enrollments = enrollmentsSnapshot.docs.map((doc) => EnrollmentModel.fromMap(doc.data(), doc.id)).toList();

      // 3. Crear un set de nombres de materias desde las inscripciones ya filtradas.
      final enrolledSubjectNames = _enrollments.map((e) => e.subject.trim().toLowerCase()).toSet();

      // 4. Cargar TODAS las evidencias del alumno
      final evidencesSnapshot = await _db
          .collection('evidencias')
          .where('uid', isEqualTo: studentId)
          .get();

      // 5. Limpiar y llenar las evidencias aplicando el filtro por NOMBRE de materia
      _groupedEvidences.clear();
      for (var doc in evidencesSnapshot.docs) {
        final evidence = EvidenceModel.fromMap(doc.data(), doc.id);
        
        // FILTRO CLAVE: Comprobar si la materia de la evidencia está en las materias inscritas (y filtradas por academia).
        if (enrolledSubjectNames.contains(evidence.subject.trim().toLowerCase())) {
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
      await _authRepo.assignSubjectGrade(
        studentId: student.id,
        enrollmentId: enrollmentId,
        finalGrade: grade,
        status: isAccredited ? 'ACREDITADO' : 'NO_ACREDITADO',
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
