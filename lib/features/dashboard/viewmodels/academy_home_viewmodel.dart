import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/user_model.dart';

class AcademyViewModel extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // El ID o Nombre de la academia del Jefe Logueado
  // (En una app real, esto vendría del perfil del Jefe. Aquí lo harcodeamos para probar).
  final String currentAcademy = 'SISTEMAS';

  bool _isLoading = true;
  String? _errorMessage;
  List<UserModel> _pendingStudents = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<UserModel> get pendingStudents => _pendingStudents;

  // Lista simulada de profesores disponibles en esta academia
  final List<String> availableProfessors = [
    "Prof. Alan Turing",
    "Prof. Grace Hopper",
    "Prof. John von Neumann"
  ];

  AcademyViewModel() {
    loadPendingStudents();
  }

  // 1. Cargar alumnos PENDIENTES de mi ACADEMIA
  Future<void> loadPendingStudents() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _db.collection('users')
          .where('role', isEqualTo: 'student') // Solo alumnos
          .where('academy', isEqualTo: currentAcademy) // De MI academia
          .where('status', isEqualTo: 'PENDIENTE_ASIGNACION') // Que necesiten tutor
          .get();

      _pendingStudents = snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();

    } catch (e) {
      _errorMessage = "Error cargando alumnos: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 2. Asignar Tutor
  Future<bool> assignTutor(String studentId, String professorName) async {
    try {
      await _db.collection('users').doc(studentId).update({
        'tutor_name': professorName,
        'status': 'EN_CURSO', // ¡Aquí liberamos al alumno!
        'assigned_at': FieldValue.serverTimestamp(),
      });

      // Recargamos la lista para que desaparezca el asignado
      await loadPendingStudents();
      return true;
    } catch (e) {
      _errorMessage = "Error asignando tutor: $e";
      notifyListeners();
      return false;
    }
  }
}