import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/enrollment_model.dart';
import '../../../data/models/evidence_model.dart';
import '../../../data/repositories/auth_repository.dart'; // Import AuthRepository

class StudentDetailViewModel extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthRepository _authRepo; // Add repository instance

  bool _isLoading = true;
  String? _errorMessage;
  List<EnrollmentModel> _enrollments = [];
  List<EvidenceModel> _evidences = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<EnrollmentModel> get enrollments => _enrollments;
  List<EvidenceModel> get evidences => _evidences;

  final String studentId;

  // Updated constructor to accept the repository
  StudentDetailViewModel({required this.studentId, required AuthRepository authRepo})
      : _authRepo = authRepo {
    loadStudentData();
  }

  Future<void> loadStudentData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final enrollmentsSnapshot = await _db
          .collection('enrollments')
          .where('uid', isEqualTo: studentId)
          .orderBy('assigned_at', descending: true)
          .get();
      _enrollments = enrollmentsSnapshot.docs
          .map((doc) => EnrollmentModel.fromMap(doc.data(), doc.id))
          .toList();

      final evidencesSnapshot = await _db
          .collection('evidencias')
          .where('uid', isEqualTo: studentId)
          .orderBy('uploaded_at', descending: true)
          .get();
      _evidences = evidencesSnapshot.docs
          .map((doc) => EvidenceModel.fromMap(doc.data(), doc.id))
          .toList();

    } catch (e) {
      _errorMessage = "Error cargando los datos del alumno: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- NEW: Method to review an evidence ---
  Future<bool> reviewEvidence({
    required String evidenceId,
    required bool isApproved,
    String? feedback,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepo.reviewEvidence(
        evidenceId: evidenceId,
        newStatus: isApproved ? 'APROBADA' : 'RECHAZADA',
        feedback: feedback,
      );
      // Reload data to reflect the change in the UI immediately
      await loadStudentData();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
