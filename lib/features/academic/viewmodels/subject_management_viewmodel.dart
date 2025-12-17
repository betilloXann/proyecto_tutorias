import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/subject_model.dart';
import '../../../data/models/professor_model.dart';
import '../../../data/models/user_model.dart';

class SubjectManagementViewModel extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final String currentAcademy;

  bool _isLoading = true;
  String? _errorMessage;
  List<SubjectModel> _subjects = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<SubjectModel> get subjects => _subjects;

  List<UserModel> availableProfessors = [];

  SubjectManagementViewModel({required this.currentAcademy}) {
    loadSubjects();
  }

  Future<void> loadSubjects() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final snapshot = await _db
          .collection('subjects')
          .where('academy', isEqualTo: currentAcademy)
          .get();

      _subjects = snapshot.docs.map((doc) => SubjectModel.fromMap(doc.data(), doc.id)).toList();

      // Sort subjects alphabetically by name
      _subjects.sort((a, b) => a.name.compareTo(b.name));

    } catch (e) {
      _errorMessage = "Error al cargar las materias: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cargar lista de profesores reales desde 'users'
  Future<void> loadAvailableProfessors() async {
    try {
      final snapshot = await _db.collection('users')
          .where('role', isEqualTo: 'professor')
          .where('academies', arrayContains: currentAcademy)
          .get();

      availableProfessors = snapshot.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint("Error cargando profesores: $e");
    }
  }

  Future<bool> addSubject(String subjectName) async {
    if (subjectName.isEmpty) {
      _errorMessage = "El nombre de la materia no puede estar vacío.";
      notifyListeners();
      return false;
    }

    try {
      await _db.collection('subjects').add({
        'name': subjectName,
        'academy': currentAcademy,
        'professors': [],
      });
      await loadSubjects();
      return true;
    } catch (e) {
      _errorMessage = "Error al añadir la materia: $e";
      notifyListeners();
      return false;
    }
  }

  Future<bool> addProfessorToSubject(String subjectId, UserModel professorUser, String schedule) async {
    try {
      // Creamos el modelo con ID real, nombre real y correo real
      final newProfessor = ProfessorModel(
          uid: professorUser.id,
          name: professorUser.name,
          email: professorUser.email,
          schedule: schedule
      );

      await _db.collection('subjects').doc(subjectId).update({
        'professors': FieldValue.arrayUnion([newProfessor.toMap()]),
      });
      await loadSubjects();
      return true;
    } catch (e) {
      _errorMessage = "Error al añadir el profesor: $e";
      notifyListeners();
      return false;
    }
  } // <--- AQUI HABÍA UNA LLAVE EXTRA QUE ELIMINÉ

  Future<bool> updateProfessorToSubject(String subjectId, ProfessorModel oldProfessor, String newProfessorName, String newSchedule) async {
    if (newProfessorName.isEmpty || newSchedule.isEmpty) {
      _errorMessage = "El nombre y el horario no pueden estar vacíos.";
      notifyListeners();
      return false;
    }

    try {
      // CORRECCIÓN IMPORTANTE:
      // Mantenemos el uid y email del profesor original, solo actualizamos horario (y nombre si fuera corrección de typo)
      final newProfessor = ProfessorModel(
          uid: oldProfessor.uid,     // <--- Mantener ID
          email: oldProfessor.email, // <--- Mantener Email
          name: newProfessorName,
          schedule: newSchedule
      );

      // Usamos arrayRemove y arrayUnion para "reemplazar" el objeto en el array de Firestore
      await _db.collection('subjects').doc(subjectId).update({
        'professors': FieldValue.arrayRemove([oldProfessor.toMap()]),
      });
      await _db.collection('subjects').doc(subjectId).update({
        'professors': FieldValue.arrayUnion([newProfessor.toMap()]),
      });

      await loadSubjects();
      return true;
    } catch (e) {
      _errorMessage = "Error al actualizar el profesor: $e";
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeProfessorFromSubject(String subjectId, ProfessorModel professor) async {
    try {
      await _db.collection('subjects').doc(subjectId).update({
        'professors': FieldValue.arrayRemove([professor.toMap()]),
      });
      await loadSubjects();
      return true;
    } catch (e) {
      _errorMessage = "Error al eliminar el profesor: $e";
      notifyListeners();
      return false;
    }
  }
}