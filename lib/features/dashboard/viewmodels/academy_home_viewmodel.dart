import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/user_model.dart';

class AcademyViewModel extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String currentAcademy = 'SISTEMAS';

  bool _isLoading = true;
  String? _errorMessage;
  List<UserModel> _pendingStudents = [];
  List<UserModel> _assignedStudents = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<UserModel> get pendingStudents => _pendingStudents;
  List<UserModel> get assignedStudents => _assignedStudents;

  // --- DATOS PARA EL FORMULARIO ---
  // En el futuro esto podría venir de una colección 'subjects' y 'professors' en Firebase
  final List<String> availableSubjects = [
    "Programación Orientada a Objetos",
    "Estructuras de Datos",
    "Calculo Diferencial",
    "Ingeniería de Software",
    "Base de Datos",
  ];

  final List<String> availableProfessors = [
    "Prof. Alan Turing",
    "Prof. Grace Hopper",
    "Prof. John von Neumann",
    "Prof. Ada Lovelace",
  ];

  AcademyViewModel() {
    loadStudents();
  }

  Future<void> loadStudents() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Obtenemos los alumnos pendientes
      final pendingSnapshot = await _db.collection('users')
          .where('role', isEqualTo: 'student')
          .where('academy', isEqualTo: currentAcademy)
          .where('status', isEqualTo: 'PENDIENTE_ASIGNACION')
          .get();

      _pendingStudents = pendingSnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();
          
      // Obtenemos los alumnos que ya tienen una materia asignada
      final assignedSnapshot = await _db.collection('users')
          .where('role', isEqualTo: 'student')
          .where('academy', isEqualTo: currentAcademy)
          .where('status', isEqualTo: 'EN_CURSO')
          .get();

      _assignedStudents = assignedSnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();

    } catch (e) {
      _errorMessage = "Error cargando alumnos: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ESTA ES LA FUNCIÓN CLAVE (Ya la tenías, solo aseguramos que notifique)
  Future<bool> assignSubject({
    required String studentId,
    required String subjectName,
    required String professorName,
    required String schedule,
    required String salon,
  }) async {
    try {
      // 1. Crear el registro en 'enrollments'
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

      // 2. Liberar al alumno (cambiar status global)
      await _db.collection('users').doc(studentId).update({
        'status': 'EN_CURSO',
      });

      // Recargamos ambas listas para que la UI se actualice al momento.
      await loadStudents();

      return true;
    } catch (e) {
      _errorMessage = "Error asignando: $e";
      notifyListeners();
      return false;
    }
  }
}
