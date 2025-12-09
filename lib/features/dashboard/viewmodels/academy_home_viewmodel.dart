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

  // Listas de alumnos por estado
  List<UserModel> _preRegisteredStudents = []; // <--- NUEVA LISTA
  List<UserModel> _pendingStudents = [];
  List<UserModel> _assignedStudents = [];
  List<UserModel> _accreditedStudents = [];
  List<UserModel> _notAccreditedStudents = [];

  List<SubjectModel> _subjects = [];
  List<SubjectModel> _availableSubjectsForStudent = [];

  // CACHE: Mapa para saber qué materias ya tiene cada alumno (ID Alumno -> Lista de materias)
  final Map<String, Set<String>> _studentEnrollmentsCache = {};

  final Map<String, String> _subjectAbbreviationMap = {
    'LABORATORIO DE ELECTRICIDAD Y CONTROL': 'LAB. ELECT. Y CONTROL',
    'ARQUITECTURA Y ORGANIZACIÓN DE LAS COMPUTADORAS': 'ARQ. Y ORG. COMP.',
    'APLICACIÓN DE SISTEMAS DIGITALES': 'APLIC. SIST. DIGITALES',
  };

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<UserModel> get preRegisteredStudents => _preRegisteredStudents; // <--- GETTER NUEVO
  List<UserModel> get pendingStudents => _pendingStudents;
  List<UserModel> get assignedStudents => _assignedStudents;
  List<UserModel> get accreditedStudents => _accreditedStudents;
  List<UserModel> get notAccreditedStudents => _notAccreditedStudents;
  List<SubjectModel> get subjects => _subjects;
  List<SubjectModel> get availableSubjectsForStudent => _availableSubjectsForStudent;

  AcademyViewModel({required this.myAcademies}) {
    loadInitialData();
  }

  // --- LÓGICA CORREGIDA: Filtra materias que el alumno YA tiene ---
  void filterSubjectsForStudent(UserModel student) {
    // 1. Obtenemos las materias que el alumno YA tiene inscritas (del cache)
    final enrolledSubjects = _studentEnrollmentsCache[student.id] ?? {};

    if (student.subjectsToTake.isEmpty) {
      // Si no tiene materias obligatorias definidas, mostramos todas MENOS las que ya tiene
      _availableSubjectsForStudent = _subjects.where((subject) {
        return !enrolledSubjects.contains(subject.name.trim().toLowerCase());
      }).toList();
    } else {
      final studentSubjectsNormalized = student.subjectsToTake.map((s) => s.trim().toLowerCase()).toSet();

      _availableSubjectsForStudent = _subjects.where((subject) {
        final subjectNameNormalized = subject.name.trim().toLowerCase();

        // 2. FILTRO CLAVE: Si ya la tiene inscrita, NO la mostramos (return false)
        if (enrolledSubjects.contains(subjectNameNormalized)) {
          return false;
        }

        // 3. Verificamos si es una materia que debe tomar
        if (studentSubjectsNormalized.contains(subjectNameNormalized)) {
          return true;
        }

        // 4. Verificamos abreviaciones (por si acaso)
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

  Future<void> _loadStudents() async {
    if (myAcademies.isEmpty) return;

    final academySubjectNames = _subjects.map((s) => s.name.toLowerCase()).toSet();

    final studentsSnapshot = await _db
        .collection('users')
        .where('role', isEqualTo: 'student')
        .where('academies', arrayContainsAny: myAcademies)
        .get();

    final studentIds = studentsSnapshot.docs.map((doc) => doc.id).toList();

    // Limpiamos el cache antes de llenarlo
    _studentEnrollmentsCache.clear();

    if (studentIds.isNotEmpty) {
      // Pedimos las inscripciones en lotes de 10
      for (int i = 0; i < studentIds.length; i += 10) {
        final chunk = studentIds.sublist(i, i + 10 > studentIds.length ? studentIds.length : i + 10);
        final enrollmentsSnapshot = await _db.collection('enrollments').where('uid', whereIn: chunk).get();

        for (var doc in enrollmentsSnapshot.docs) {
          final data = doc.data();
          final studentId = data['uid'] as String;
          final subjectName = data['subject'] as String;

          // Guardamos en el CACHE GLOBAL de la clase
          _studentEnrollmentsCache.putIfAbsent(studentId, () => {}).add(subjectName.trim().toLowerCase());
        }
      }
    }

    // Reiniciamos las listas
    _preRegisteredStudents = [];
    _pendingStudents = [];
    _assignedStudents = [];
    _accreditedStudents = [];
    _notAccreditedStudents = [];

    for (var doc in studentsSnapshot.docs) {
      final student = UserModel.fromMap(doc.data(), doc.id);

      // --- AQUÍ AGREGAMOS LA LÓGICA DE PRE-REGISTRO ---
      if (student.status == 'PRE_REGISTRO') {
        _preRegisteredStudents.add(student);
        continue;
      }
      if (student.status == 'ACREDITADO') {
        _accreditedStudents.add(student);
        continue;
      }
      if (student.status == 'NO_ACREDITADO') {
        _notAccreditedStudents.add(student);
        continue;
      }

      // Lógica Pendiente vs En Curso
      final requiredSubjectsInThisAcademy = student.subjectsToTake
          .where((subjName) => academySubjectNames.contains(subjName.toLowerCase()))
          .toSet();

      // Consultamos el cache que acabamos de llenar
      final enrolledSubjects = _studentEnrollmentsCache[student.id] ?? {};

      final enrolledSubjectsInThisAcademy = enrolledSubjects
          .where((subjName) => academySubjectNames.contains(subjName))
          .toSet();

      if (requiredSubjectsInThisAcademy.isEmpty) {
        if (enrolledSubjectsInThisAcademy.isNotEmpty) {
          _assignedStudents.add(student);
        } else {
          _pendingStudents.add(student);
        }
      } else if (enrolledSubjectsInThisAcademy.length >= requiredSubjectsInThisAcademy.length) {
        // Ya tiene TODAS las materias de ESTA academia asignadas
        _assignedStudents.add(student);
      } else {
        // Le faltan materias
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

      // Lógica de actualización de estatus global del usuario
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

      await loadInitialData(); // Recargar todo para actualizar listas y dropdowns
      return true;
    } catch (e) {
      _errorMessage = "Error asignando: $e";
      notifyListeners();
      return false;
    }
  }
}