import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';

class DepartmentHomeViewModel extends ChangeNotifier {
  final AuthRepository _authRepo;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _isLoading = true;
  String? _errorMessage;

  List<UserModel> _allStudents = [];
  List<UserModel> _filteredStudents = [];

  // --- UPDATED: Statistics ---
  int get totalStudents => _allStudents.length;
  int get preRegisteredCount => _allStudents.where((s) => s.status == 'PRE_REGISTRO').length;
  int get pendingCount => _allStudents.where((s) => s.status == 'PENDIENTE_ASIGNACION').length;
  int get inCourseCount => _allStudents.where((s) => s.status == 'EN_CURSO').length;
  int get accreditedCount => _allStudents.where((s) => s.status == 'ACREDITADO').length;
  int get notAccreditedCount => _allStudents.where((s) => s.status == 'NO_ACREDITADO').length;

  Map<String, int> get studentsByAcademy {
    final Map<String, int> counts = {};
    for (final student in _allStudents) {
      // Como 'academies' es una lista, recorremos cada una
      for (final academy in student.academies) {
        // Normalizamos el nombre (opcional, por si hay diferencias de mayúsculas)
        final key = academy.trim(); 
        counts[key] = (counts[key] ?? 0) + 1;
      }
    }
    return counts;
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<UserModel> get students => _filteredStudents;

  DepartmentHomeViewModel(this._authRepo) {
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final snapshot = await _db.collection('users').where('role', isEqualTo: 'student').get();
      _allStudents = snapshot.docs.map((doc) => UserModel.fromMap(doc.data(), doc.id)).toList();
      _filteredStudents = List.from(_allStudents);
    } catch (e) {
      _errorMessage = "Error cargando datos: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void searchStudent(String query) {
    if (query.isEmpty) {
      _filteredStudents = List.from(_allStudents);
    } else {
      final lowerQuery = query.toLowerCase();
      _filteredStudents = _allStudents.where((student) {
        return student.name.toLowerCase().contains(lowerQuery) ||
            student.boleta.contains(lowerQuery);
      }).toList();
    }
    notifyListeners();
  }

  // Método auxiliar para filtrar vista por academia (Opcional, para navegación futura)
  List<UserModel> getStudentsByAcademy(String academyName) {
    return _allStudents.where((s) => s.academies.contains(academyName)).toList();
  }

  Future<void> logout({VoidCallback? onDone}) async {
    await _authRepo.signOut();
    onDone?.call();
  }
}
