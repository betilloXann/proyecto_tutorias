import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class SimulationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Random _rnd = Random();

  final List<String> _names = ['Juan', 'Ana', 'Luis', 'Maria', 'Pedro', 'Sofia', 'Carlos', 'Lucia', 'Miguel', 'Elena', 'Diego', 'Valentina'];
  final List<String> _lastNames = ['Perez', 'Lopez', 'Garcia', 'Martinez', 'Rodriguez', 'Hernandez', 'Gonzalez', 'Ramirez', 'Torres', 'Flores'];
  final List<String> _subjects = ['PROGRAMACION I', 'CALCULO DIFERENCIAL', 'ALGEBRA LINEAL', 'FISICA CLASICA', 'QUIMICA BASICA', 'HUMANIDADES I'];
  final List<String> _academies = ['SISTEMAS', 'BASICAS', 'REDES'];

  Future<void> simulateSemester({
    required String periodId, // Ej: "24/1"
    required int studentCount,
  }) async {
    debugPrint("--- INICIANDO SIMULACIÓN PARA EL PERIODO $periodId ---");

    // Usamos lotes (batches) para eficiencia
    WriteBatch batch = _db.batch();
    int opCount = 0;

    for (int i = 0; i < studentCount; i++) {
      DocumentReference userRef = _db.collection('users').doc();

      // Generar boleta basada en el año del periodo (Ej: 24/1 -> Boleta 2024...)
      String yearPrefix = periodId.split('/')[0];
      String boleta = '20$yearPrefix${_rnd.nextInt(90000) + 10000}';
      String name = '${_names[_rnd.nextInt(_names.length)]} ${_lastNames[_rnd.nextInt(_lastNames.length)]}';

      // 1. Crear Usuario
      // Nota: Creamos el usuario con status 'ACREDITADO' por defecto para el historial,
      // pero esto se recalculará dinámicamente en el Dashboard.
      batch.set(userRef, {
        'uid': userRef.id,
        'boleta': boleta,
        'name': name,
        'email_inst': 'a$boleta@alumno.ipn.mx',
        'academies': [_academies[_rnd.nextInt(_academies.length)]],
        'subjects_to_take': [],
        'status': 'ACREDITADO',
        'role': 'student',
        'created_at': FieldValue.serverTimestamp(),
      });
      opCount++;

      // 2. Generar Materias (Inscripciones)
      int subjectCount = _rnd.nextInt(3) + 2; // Entre 2 y 4 materias
      bool hasFailed = false;

      for (int j = 0; j < subjectCount; j++) {
        DocumentReference enrollRef = _db.collection('enrollments').doc();
        String subject = _subjects[j % _subjects.length];

        // Probabilidad: 70% Aprobado, 30% Reprobado
        bool passed = _rnd.nextDouble() < 0.7;
        if (!passed) hasFailed = true;

        double grade = passed ? (6.0 + _rnd.nextInt(4)) : (0.0 + _rnd.nextInt(5));

        batch.set(enrollRef, {
          'uid': userRef.id,
          'subject': subject,
          'periodId': periodId, // <--- LA CLAVE DE T0D0
          'status': passed ? 'ACREDITADO' : 'NO_ACREDITADO',
          'academy': 'SISTEMAS',
          'final_grade': grade,
          'assigned_at': DateTime.now(), // Simplificado
          'graded_at': DateTime.now(),
        });
        opCount++;
      }

      // Si reprobó alguna, actualizamos su status "final" en el usuario
      // (aunque el dashboard histórico usará los enrollments)
      if (hasFailed) {
        batch.update(userRef, {'status': 'NO_ACREDITADO'});
        opCount++;
      }

      // Commit parcial para no exceder límite de 500
      if (opCount >= 400) {
        await batch.commit();
        batch = _db.batch();
        opCount = 0;
      }
    }

    if (opCount > 0) await batch.commit();
    debugPrint("--- SIMULACIÓN FINALIZADA: $studentCount alumnos en $periodId ---");
  }
}