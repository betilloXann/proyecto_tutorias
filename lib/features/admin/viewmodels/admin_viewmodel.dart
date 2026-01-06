import 'package:flutter/material.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../data/services/simulation_service.dart';
import '../../../data/models/enrollment_model.dart';

class AdminViewModel extends ChangeNotifier {
  final AdminRepository _repository;
  final SimulationService _simulationService = SimulationService();
  bool _isLoading = false;

  AdminViewModel(this._repository);
  Stream<List<Map<String, dynamic>>> get staffStream => _repository.getStaffStream();

  bool get isLoading => _isLoading;

  // Script: Regenerar Jefes
  Future<void> runRegenerateStaff() async {
    _isLoading = true;
    notifyListeners();

    final staff = [
      {'email': 'flores@computacion.ipn.mx', 'pass': 'flores', 'name': 'Jefe Computación', 'role': 'jefe_academia', 'academies': ['COMPUTACION']},
      {'email': 'marisol@electrica.ipn.mx', 'pass': 'marisol', 'name': 'Jefe Lab. Elect.', 'role': 'jefe_academia', 'academies': ['LAB. ELECT. Y CONTROL']},
      {'email': 'abdiel@informatica.ipn.mx', 'pass': 'abdiel', 'name': 'Jefe Informática', 'role': 'jefe_academia', 'academies': ['INFORMATICA']},
      {'email': 'fernando@tutorias.ipn.mx', 'pass': 'fernando', 'name': 'Fernando Admin', 'role': 'tutorias', 'academies': []},
    ];

    for (var user in staff) {
      try {
        await _repository.createUser(
          email: user['email'] as String,
          password: user['pass'] as String,
          name: user['name'] as String,
          role: user['role'] as String,
          academies: List<String>.from(user['academies'] as Iterable),
        );
      } catch (e) { 
        debugPrint("Error creando staff: $e"); 
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  // Script: Borrar Alumnos
  Future<Map<String, int>> runDeleteStudents() async {
    _isLoading = true;
    notifyListeners();
    final results = await _repository.deleteStudents();
    _isLoading = false;
    notifyListeners();
    return results;
  }

  // Script: Generar 40 Alumnos
  Future<void> runGenerateSampleStudents({int periodOffset = 0}) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Calculamos el periodo string (ej: "24/2") basado en el offset
      DateTime targetDate = DateTime.now();
      if (periodOffset != 0) {
        // Restar semestres (aprox 6 meses)
        int monthsToRemove = periodOffset.abs() * 6;
        targetDate = targetDate.subtract(Duration(days: monthsToRemove * 30));
      }

      String periodId = EnrollmentModel.getPeriodId(targetDate);

      // Llamamos al servicio
      await _simulationService.simulateSemester(
          periodId: periodId,
          studentCount: 40
      );

    } catch (e) {
      debugPrint("Error generando simulación: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createSingleStaff({
    required String email,
    required String name,
    required String role,
    required String academy,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.createUser(
        email: email,
        password: 'Password123',
        name: name,
        role: role,
        academies: role == 'jefe_academia' ? [academy] : [],
      );
    } catch (e) {
      debugPrint("Error en ViewModel al crear staff: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}