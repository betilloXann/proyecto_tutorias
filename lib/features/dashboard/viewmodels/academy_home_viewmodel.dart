import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/subject_model.dart';

class AcademyViewModel extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  final List<String> myAcademies; 

  bool _isLoading = true;
  String? _errorMessage;
  List<UserModel> _pendingStudents = [];
  List<UserModel> _assignedStudents = [];
  List<UserModel> _accreditedStudents = [];
  List<UserModel> _notAccreditedStudents = [];
  List<SubjectModel> _subjects = [];
  List<SubjectModel> _availableSubjectsForStudent = [];

  final Map<String, String> _subjectAbbreviationMap = {
    'LABORATORIO DE ELECTRICIDAD Y CONTROL': 'LAB. ELECT. Y CONTROL',
    'ARQUITECTURA Y ORGANIZACIÓN DE LAS COMPUTADORAS': 'ARQ. Y ORG. COMP.',
    'APLICACIÓN DE SISTEMAS DIGITALES': 'APLIC. SIST. DIGITALES',
  };

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<UserModel> get pendingStudents => _pendingStudents;
  List<UserModel> get assignedStudents => _assignedStudents;
  List<UserModel> get accreditedStudents => _accreditedStudents;
  List<UserModel> get notAccreditedStudents => _notAccreditedStudents;
  List<SubjectModel> get subjects => _subjects;
  List<SubjectModel> get availableSubjectsForStudent => _availableSubjectsForStudent;

  AcademyViewModel({required this.myAcademies}) {
    loadInitialData();
  }

  void filterSubjectsForStudent(UserModel student) {
    if (student.subjectsToTake.isEmpty) {
      _availableSubjectsForStudent = List.from(_subjects);
    } else {
      final studentSubjectsNormalized = student.subjectsToTake.map((s) => s.trim().toLowerCase()).toSet();
      
      _availableSubjectsForStudent = _subjects.where((subject) {
        final subjectNameNormalized = subject.name.trim().toLowerCase();
        if (studentSubjectsNormalized.contains(subjectNameNormalized)) {
          return true;
        }
        final upperCaseSubjectName = subject.name.toUpperCase();
        final abbreviation = _subjectAbbreviationMap[upperCaseSubjectName];
        if (abbreviation != null && studentSubjectsNormalized.contains(abbreviation.toLowerCase())) {
          return true;
        }
        return false;
      }).toList();
    }
    notifyListeners();
  }

  Future<void> loadInitialData() async {
    if (myAcademies.isEmpty) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _loadSubjects();
      await _loadStudents();
    } catch (e) {
      _errorMessage = "Error cargando datos: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- FIX: Smarter student loading logic ---
  Future<void> _loadStudents() async {
    if (myAcademies.isEmpty) return;

    // 1. Get all subjects offered by this academy (already loaded in _subjects)
    final academySubjectNames = _subjects.map((s) => s.name.toLowerCase()).toSet();

    // 2. Get all students related to this academy
    final studentsSnapshot = await _db
        .collection('users')
        .where('role', isEqualTo: 'student')
        .where('academies', arrayContainsAny: myAcademies)
        .get();

    // 3. Get all enrollments for these students in batches
    final studentIds = studentsSnapshot.docs.map((doc) => doc.id).toList();
    final Map<String, List<String>> studentEnrollments = {};
    if (studentIds.isNotEmpty) {
      for (int i = 0; i < studentIds.length; i += 10) {
        final chunk = studentIds.sublist(i, i + 10 > studentIds.length ? studentIds.length : i + 10);
        final enrollmentsSnapshot = await _db.collection('enrollments').where('uid', whereIn: chunk).get();
        for (var doc in enrollmentsSnapshot.docs) {
          final data = doc.data();
          final studentId = data['uid'] as String;
          final subjectName = data['subject'] as String;
          studentEnrollments.putIfAbsent(studentId, () => []).add(subjectName.toLowerCase());
        }
      }
    }

    // 4. Clear lists and process students
    _pendingStudents = [];
    _assignedStudents = [];
    _accreditedStudents = [];
    _notAccreditedStudents = [];

    for (var doc in studentsSnapshot.docs) {
      final student = UserModel.fromMap(doc.data(), doc.id);

      if (student.status == 'ACREDITADO') {
        _accreditedStudents.add(student);
        continue;
      }
      if (student.status == 'NO_ACREDITADO') {
        _notAccreditedStudents.add(student);
        continue;
      }

      // Logic for PENDING and IN_CURSO students
      final requiredSubjectsInThisAcademy = student.subjectsToTake
          .where((subjName) => academySubjectNames.contains(subjName.toLowerCase()))
          .toSet();

      final enrolledSubjects = (studentEnrollments[student.id] ?? []).toSet();
      
      final enrolledSubjectsInThisAcademy = enrolledSubjects
          .where((subjName) => academySubjectNames.contains(subjName.toLowerCase()))
          .toSet();

      if (requiredSubjectsInThisAcademy.isEmpty) {
        // This student has no required subjects in this academy, but is related to it.
        // We can consider them 'in progress' for this view.
        _assignedStudents.add(student);
      } else if (enrolledSubjectsInThisAcademy.length >= requiredSubjectsInThisAcademy.length) {
        // Student has completed all subjects for THIS academy.
        _assignedStudents.add(student);
      } else {
        // Student still has pending subjects in THIS academy.
        _pendingStudents.add(student);
      }
    }
  }


  Future<void> _loadSubjects() async {
    final Set<String> searchTerms = {};
    for (var academy in myAcademies) {
      searchTerms.add(academy);
      final abbreviation = _subjectAbbreviationMap.entries.firstWhere((entry) => entry.key == academy, orElse: () => const MapEntry('', '')).value;
      if (abbreviation.isNotEmpty) {
        searchTerms.add(abbreviation);
      }
    }

    if (searchTerms.isEmpty) {
      _subjects = [];
      return;
    }

    final snapshot = await _db
        .collection('subjects')
        .where('academy', whereIn: searchTerms.toList())
        .get();
        
    _subjects = snapshot.docs.map((doc) => SubjectModel.fromMap(doc.data(), doc.id)).toList();
    _subjects.sort((a, b) => a.name.compareTo(b.name));
  }

  Future<bool> assignSubject({
    required String studentId,
    required String subjectName,
    required String professorName,
    required String schedule,
    required String salon,
  }) async {
    try {
      final targetAcademy = myAcademies.isNotEmpty ? myAcademies.first : 'SISTEMAS';

      await _db.collection('enrollments').add({
        'uid': studentId,
        'subject': subjectName,
        'professor': professorName,
        'schedule': schedule,
        'salon': salon,
        'status': 'EN_CURSO',
        'academy': targetAcademy, 
        'assigned_at': FieldValue.serverTimestamp(),
      });

      // Global status verification logic (remains the same)
      final userDoc = await _db.collection('users').doc(studentId).get();
      if (userDoc.exists) {
        final student = UserModel.fromMap(userDoc.data()!, userDoc.id);
        final requiredSubjectsCount = student.subjectsToTake.length;

        final enrollmentsSnapshot = await _db.collection('enrollments').where('uid', isEqualTo: studentId).get();
        final enrolledSubjectsCount = enrollmentsSnapshot.docs.length;

        if (enrolledSubjectsCount >= requiredSubjectsCount) {
          await _db.collection('users').doc(studentId).update({'status': 'EN_CURSO'});
        }
      }

      await loadInitialData();
      return true;
    } catch (e) {
      _errorMessage = "Error asignando: $e";
      notifyListeners();
      return false;
    }
  }
}
