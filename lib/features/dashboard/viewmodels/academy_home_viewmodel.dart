import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/subject_model.dart'; // <-- Import SubjectModel

class AcademyViewModel extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String currentAcademy = 'SISTEMAS';

  bool _isLoading = true;
  String? _errorMessage;
  List<UserModel> _pendingStudents = [];
  List<UserModel> _assignedStudents = [];

  // --- NEW: Load subjects from Firestore ---
  List<SubjectModel> _subjects = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<UserModel> get pendingStudents => _pendingStudents;
  List<UserModel> get assignedStudents => _assignedStudents;
  List<SubjectModel> get subjects => _subjects; // Getter for the new list

  AcademyViewModel() {
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Using Future.wait to load both simultaneously
      await Future.wait([
        _loadStudents(),
        _loadSubjects(),
      ]);
    } catch (e) {
      _errorMessage = "Error cargando datos: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadStudents() async {
    final pendingSnapshot = await _db.collection('users')
        .where('role', isEqualTo: 'student')
        .where('academy', isEqualTo: currentAcademy)
        .where('status', isEqualTo: 'PENDIENTE_ASIGNACION')
        .get();
    _pendingStudents = pendingSnapshot.docs.map((doc) => UserModel.fromMap(doc.data(), doc.id)).toList();

    final assignedSnapshot = await _db.collection('users')
        .where('role', isEqualTo: 'student')
        .where('academy', isEqualTo: currentAcademy)
        .where('status', isEqualTo: 'EN_CURSO')
        .get();
    _assignedStudents = assignedSnapshot.docs.map((doc) => UserModel.fromMap(doc.data(), doc.id)).toList();
  }

  Future<void> _loadSubjects() async {
    final snapshot = await _db
        .collection('subjects')
        .where('academy', isEqualTo: currentAcademy)
        .get();
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

      await loadInitialData(); // Reload all data

      return true;
    } catch (e) {
      _errorMessage = "Error asignando: $e";
      notifyListeners();
      return false;
    }
  }
}
