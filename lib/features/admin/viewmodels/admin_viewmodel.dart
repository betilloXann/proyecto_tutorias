import 'package:flutter/material.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../data/models/enrollment_model.dart';

class AdminViewModel extends ChangeNotifier {
  final AdminRepository _repository;
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

    final random = Random();
    final academies = ['COMPUTACION', 'LAB. ELECT. Y CONTROL', 'INFORMATICA'];

    // Lista de materias comunes para simular
    final subjectsList = [
      'Programación Orientada a Objetos',
      'Estructuras de Datos',
      'Lógica de Programación',
      'Bases de Datos',
      'Ingeniería de Pruebas',
      'Algoritmos Cimputacionales',
      'Dispositivos Programables'
    ];

    // Estados posibles para el reporte
    final enrollmentStatuses = ['ACREDITADO', 'NO_ACREDITADO', 'EN_CURSO', 'PRE_REGISTRO', 'PENDIENTE'];

    final isHistorical = periodOffset < 0;

    for (int i = 1; i <= 40; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      try {
        final academy = academies[i % 3]; // Rotar academias

        // Calcular fecha simulada
        DateTime simulatedDate = DateTime.now();
        if (periodOffset != 0) {
          // Restar o sumar semestres (aprox 6 meses por offset)
          simulatedDate = simulatedDate.add(Duration(days: 180 * periodOffset));
        }

        // 1. Crear el USUARIO
        final uid = await _repository.createUser(
          email: 'alumno_test_$i@ipn.mx',
          password: 'alumno123',
          name: 'Test ${isHistorical ? "Pasado" : "Actual"} $i',
          role: 'student',
          academies: [academy],
          boleta: '202460${i.toString().padLeft(2, '0')}',
        );

        if (uid != null) {
          int numSubjects = random.nextInt(3) + 1;
          for (int j = 0; j < numSubjects; j++) {
            String subject = subjectsList[random.nextInt(subjectsList.length)];

            // Lógica de estatus
            String status;
            double? grade;

            if (isHistorical) {
              // En el pasado, ya terminaron el curso
              status = random.nextBool() ? 'ACREDITADO' : 'NO_ACREDITADO';
            } else {
              // En el presente, pueden estar cursando o ya haber terminado parciales
              status = enrollmentStatuses[random.nextInt(enrollmentStatuses.length)];
            }

            if (status == 'ACREDITADO') {
              grade = 6.0 + random.nextInt(4) + (random.nextInt(10) / 10);
            } else if (status == 'NO_ACREDITADO') {
              grade = random.nextInt(6) + (random.nextInt(10) / 10);
            } else {
              grade = null; // EN_CURSO usualmente no tiene calif final aún
            }

            final periodId = EnrollmentModel.getPeriodId(simulatedDate); // <--- CLAVE

            final enrollmentData = {
              'uid': uid,
              'subject': subject,
              'professor': 'Profesor Generado',
              'schedule': '10:00 - 12:00',
              'salon': 'L-20$j',
              'status': status,
              'academy': academy,
              'assigned_at': Timestamp.fromDate(simulatedDate),
              'periodId': periodId,
              'final_grade': grade,
            };

            await _repository.createStudentEnrollment(enrollmentData);
          }
        }
      } catch (e) {
        debugPrint("Error gen alumno $i: $e");
      }
    }

    _isLoading = false;
    notifyListeners();
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