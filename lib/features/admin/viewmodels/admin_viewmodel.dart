import 'package:flutter/material.dart';
import '../../../data/repositories/admin_repository.dart';

class AdminViewModel extends ChangeNotifier {
  final AdminRepository _repository;
  bool _isLoading = false;

  AdminViewModel(this._repository);

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
  Future<void> runGenerateSampleStudents() async {
    _isLoading = true;
    notifyListeners();
    
    final academies = ['COMPUTACION', 'LAB. ELECT. Y CONTROL', 'INFORMATICA'];
    final statuses = ['PRE_REGISTRO', 'PENDIENTE_ASIGNACION', 'EN_CURSO', 'ACREDITADO', 'NO_ACREDITADO'];

    for (int i = 1; i <= 40; i++) {
      try {
        // Usamos la variable statuses para asignar un estado cíclico (0 al 4)
        // Esto elimina el warning y mejora la data de prueba
        final currentStatus = statuses[(i - 1) % statuses.length];

        await _repository.createUser(
          email: 'alumno$i@ipn.mx',
          password: 'alumno123',
          name: 'Alumno Test $i',
          role: 'student',
          academies: [academies[i % 3]],
          boleta: '202460${i.toString().padLeft(2, '0')}',
          // Nota: Asegúrate de que tu repository.createUser acepte 'status'
          // Si no, puedes pasar esta lógica según tus necesidades de BD
        );
        debugPrint("Creado alumno$i con estado: $currentStatus");
      } catch (e) {
        debugPrint("Error al generar alumno$i: $e");
      }
    }

    _isLoading = false;
    notifyListeners();
  }
}