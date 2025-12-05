import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/subject_model.dart';
import '../../../data/models/professor_model.dart';

class SubjectManagementViewModel extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String currentAcademy = 'SISTEMAS';

  bool _isLoading = true;
  String? _errorMessage;
  List<SubjectModel> _subjects = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<SubjectModel> get subjects => _subjects;

  SubjectManagementViewModel() {
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
    } catch (e) {
      _errorMessage = "Error al cargar las materias: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
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

  Future<bool> addProfessorToSubject(String subjectId, String professorName, String schedule) async {
    if (professorName.isEmpty || schedule.isEmpty) {
      _errorMessage = "El nombre y el horario del profesor son obligatorios.";
      notifyListeners();
      return false;
    }

    try {
      final newProfessor = ProfessorModel(name: professorName, schedule: schedule);
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
  }

  // --- NEW: Function to update a professor's details ---
  Future<bool> updateProfessorToSubject(String subjectId, ProfessorModel oldProfessor, String newProfessorName, String newSchedule) async {
    if (newProfessorName.isEmpty || newSchedule.isEmpty) {
      _errorMessage = "El nombre y el horario no pueden estar vacíos.";
      notifyListeners();
      return false;
    }

    try {
      final newProfessor = ProfessorModel(name: newProfessorName, schedule: newSchedule);
      
      // To "edit" an item in a Firestore array, we remove the old one and add the new one.
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
