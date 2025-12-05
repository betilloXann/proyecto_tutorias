import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/subject_model.dart';

class AcademyViewModel extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String currentAcademy = 'SISTEMAS';

  bool _isLoading = true;
  String? _errorMessage;
  List<UserModel> _pendingStudents = [];
  List<UserModel> _assignedStudents = [];
  List<UserModel> _accreditedStudents = []; // <-- NEW
  List<UserModel> _notAccreditedStudents = []; // <-- NEW
  List<SubjectModel> _subjects = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<UserModel> get pendingStudents => _pendingStudents;
  List<UserModel> get assignedStudents => _assignedStudents;
  List<UserModel> get accreditedStudents => _accreditedStudents; // <-- NEW
  List<UserModel> get notAccreditedStudents => _notAccreditedStudents; // <-- NEW
  List<SubjectModel> get subjects => _subjects;

  AcademyViewModel() {
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    _isLoading = true;
    _errorMessage = null;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.wait([_loadStudents(), _loadSubjects()]);
    } catch (e) {
      _errorMessage = "Error cargando datos: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadStudents() async {
    final allStudentsSnapshot = await _db
        .collection('users')
        .where('role', isEqualTo: 'student')
        .where('academy', isEqualTo: currentAcademy)
        .get();

    // Clear lists before populating
    _pendingStudents = [];
    _assignedStudents = [];
    _accreditedStudents = [];
    _notAccreditedStudents = [];

    for (var doc in allStudentsSnapshot.docs) {
      final student = UserModel.fromMap(doc.data(), doc.id);
      switch (student.status) {
        case 'PENDIENTE_ASIGNACION':
          _pendingStudents.add(student);
          break;
        case 'EN_CURSO':
          _assignedStudents.add(student);
          break;
        case 'ACREDITADO':
          _accreditedStudents.add(student);
          break;
        case 'NO_ACREDITADO':
          _notAccreditedStudents.add(student);
          break;
      }
    }
  }

  Future<void> _loadSubjects() async {
    final snapshot = await _db.collection('subjects').where('academy', isEqualTo: currentAcademy).get();
    _subjects = snapshot.docs.map((doc) => SubjectModel.fromMap(doc.data(), doc.id)).toList();
  }

  Future<bool> assignSubject({
    required String studentId,
    required String subjectName,
    required String professorName,
    required String schedule,
    required String salon,
  }) async {
    try {
      await _db.collection('enrollments').add({
        'uid': studentId,
        'subject': subjectName,
        'professor': professorName,
        'schedule': schedule,
        'salon': salon,
        'status': 'EN_CURSO',
        'academy': currentAcademy,
        'assigned_at': FieldValue.serverTimestamp(),
      });

      await _db.collection('users').doc(studentId).update({'status': 'EN_CURSO'});
      await loadInitialData();
      return true;
    } catch (e) {
      _errorMessage = "Error asignando: $e";
      notifyListeners();
      return false;
    }
  }
}

