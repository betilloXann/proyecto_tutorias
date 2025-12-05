import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/subject_model.dart';

class AcademyViewModel extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  // 1. CAMBIO: Ahora recibimos una LISTA de academias
  final List<String> myAcademies; 

  bool _isLoading = true;
  String? _errorMessage;
  List<UserModel> _pendingStudents = [];
  List<UserModel> _assignedStudents = [];
  List<UserModel> _accreditedStudents = [];
  List<UserModel> _notAccreditedStudents = [];
  List<SubjectModel> _subjects = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<UserModel> get pendingStudents => _pendingStudents;
  List<UserModel> get assignedStudents => _assignedStudents;
  List<UserModel> get accreditedStudents => _accreditedStudents;
  List<UserModel> get notAccreditedStudents => _notAccreditedStudents;
  List<SubjectModel> get subjects => _subjects;

  // 2. CAMBIO: Constructor recibe la lista
  AcademyViewModel({required this.myAcademies}) {
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    // Validación de seguridad por si la lista viene vacía
    if (myAcademies.isEmpty) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
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
    // 3. CAMBIO: 'arrayContainsAny' busca coincidencia entre dos listas
    // Trae alumnos cuya lista 'academies' contenga AL MENOS UNA de 'myAcademies'
    final allStudentsSnapshot = await _db
        .collection('users')
        .where('role', isEqualTo: 'student')
        .where('academies', arrayContainsAny: myAcademies) 
        .get();

    _pendingStudents = [];
    _assignedStudents = [];
    _accreditedStudents = [];
    _notAccreditedStudents = [];

    for (var doc in allStudentsSnapshot.docs) {
      final student = UserModel.fromMap(doc.data(), doc.id);
      switch (student.status) {
        case 'PRE_REGISTRO':
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
    // 4. CAMBIO: 'whereIn' busca materias cuya 'academy' (String) esté en mi lista
    final snapshot = await _db
        .collection('subjects')
        .where('academy', whereIn: myAcademies)
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
      // Nota: Aquí podrías necesitar lógica extra para decidir a qué academia
      // se asigna si el jefe tiene varias. Por defecto tomamos la primera.
      final targetAcademy = myAcademies.isNotEmpty ? myAcademies.first : 'SISTEMAS';

      await _db.collection('enrollments').add({
        'uid': studentId,
        'subject': subjectName,
        'professor': professorName,
        'schedule': schedule,
        'salon': salon,
        'status': 'EN_CURSO',
        'academy': targetAcademy, // Se guarda la academia principal
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