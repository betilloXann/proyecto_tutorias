import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/enrollment_model.dart';
import '../../../data/models/evidence_model.dart';
import '../../../data/repositories/auth_repository.dart';

class StudentDetailViewModel extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthRepository _authRepo;

  bool _isLoading = true;
  String? _errorMessage;
  List<EnrollmentModel> _enrollments = [];

  Map<String, Map<String, List<EvidenceModel>>> _groupedEvidences = {};

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<EnrollmentModel> get enrollments => _enrollments;
  Map<String, Map<String, List<EvidenceModel>>> get groupedEvidences => _groupedEvidences;

  final String studentId;

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
          .get();

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
          case 'APROBADA':
            _groupedEvidences[subject]!['approved']!.add(evidence);
            break;
          case 'RECHAZADA':
            _groupedEvidences[subject]!['rejected']!.add(evidence);
            break;
          default:
            _groupedEvidences[subject]!['pending']!.add(evidence);
            break;
        }
      }

    } catch (e) {
      _errorMessage = "Error cargando los datos del alumno: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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
