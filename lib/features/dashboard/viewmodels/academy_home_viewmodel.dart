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
    // 1. Buscar por el campo NUEVO (lista)
    final query1 = _db
        .collection('users')
        .where('role', isEqualTo: 'student')
        .where('academies', arrayContainsAny: myAcademies)
        .get();

    // 2. Buscar por el campo VIEJO (texto) - Solo si myAcademies no está vacía
    // Nota: Esto buscará coincidencias con cada academia de tu lista
    final query2Futures = myAcademies.map((academy) => 
      _db.collection('users')
         .where('role', isEqualTo: 'student')
         .where('academy', isEqualTo: academy)
         .get()
    );

    // Ejecutamos todo en paralelo
    final results = await Future.wait([query1, ...query2Futures]);
    
    // Usamos un Set para evitar duplicados (por si un alumno tiene ambos campos)
    final uniqueDocs = <String, DocumentSnapshot>{};
    
    for (var snapshot in results) {
      for (var doc in snapshot.docs) {
        uniqueDocs[doc.id] = doc;
      }
    }

    _pendingStudents = [];
    _assignedStudents = [];
    _accreditedStudents = [];
    _notAccreditedStudents = [];

    // Procesamos la lista única de documentos
    for (var doc in uniqueDocs.values) {
      final student = UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      
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