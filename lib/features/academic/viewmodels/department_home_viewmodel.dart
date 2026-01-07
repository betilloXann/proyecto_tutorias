import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/enrollment_model.dart';
import '../../../data/repositories/auth_repository.dart';

class DepartmentHomeViewModel extends ChangeNotifier {
  final AuthRepository _authRepo;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _isLoading = true;
  String? _errorMessage;

  // --- CONTROL DE PERIODOS ---
  late String _selectedPeriod;
  List<String> _availablePeriods = [];

  // Alumnos cargados (la "foto" del periodo seleccionado)
  List<UserModel> _allPeriodStudents = [];

  // Mapa para saber el estatus CALCULADO de cada alumno en este periodo
  // Key: uid, Value: Status (ACREDITADO, NO_ACREDITADO, etc del periodo pasado)
  Map<String, String> _periodStatusMap = {};

  // Mapa para saber a qué academias pertenece el alumno en este periodo
  Map<String, Set<String>> _periodAcademyMap = {};

  // --- ESTADÍSTICAS ---
  int _totalStudents = 0;
  int _preRegCount = 0;
  int _pendingCount = 0;
  int _inCourseCount = 0;
  int _accreditedCount = 0;
  int _notAccreditedCount = 0;

  // Conteo de ALUMNOS por academia
  Map<String, int> _academyStudentCounts = {};

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedPeriod => _selectedPeriod;
  List<String> get availablePeriods => _availablePeriods;

  // Solo para mostrar en la tarjeta de total
  List<UserModel> get allStudents => _allPeriodStudents;

  int get totalStudents => _totalStudents;
  int get preRegisteredCount => _preRegCount;
  int get pendingCount => _pendingCount;
  int get inCourseCount => _inCourseCount;
  int get accreditedCount => _accreditedCount;
  int get notAccreditedCount => _notAccreditedCount;
  Map<String, int> get studentsByAcademy => _academyStudentCounts;

  DepartmentHomeViewModel(this._authRepo) {
    _initializePeriods();
  }

  void _initializePeriods() {
    final now = DateTime.now();
    _selectedPeriod = EnrollmentModel.getPeriodId(now);

    int year = now.year % 100;
    int sem = (now.month >= 1 && now.month <= 6) ? 1 : 2;

    _availablePeriods = [];
    for (int i = 0; i < 4; i++) {
      _availablePeriods.add('$year/$sem');
      if (sem == 1) { sem = 2; year--; } else { sem = 1; }
    }
    loadDashboardData();
  }

  void changePeriod(String newPeriod) {
    _selectedPeriod = newPeriod;
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Traer inscripciones del periodo
      final enrollSnapshot = await _db.collection('enrollments')
          .where('periodId', isEqualTo: _selectedPeriod)
          .get();

      if (enrollSnapshot.docs.isEmpty) {
        _resetStats();
        _allPeriodStudents = [];
      } else {
        // 2. Procesar estadísticas y determinar UIDs
        final uids = _processStatsFromEnrollments(enrollSnapshot.docs);

        // 3. Traer detalles de usuarios (SOLUCIÓN CHUNKS: Traer todos, no solo 10)
        if (uids.isNotEmpty) {
          _allPeriodStudents = await _fetchUsersInChunks(uids.toList());
        } else {
          _allPeriodStudents = [];
        }
      }

    } catch (e) {
      _errorMessage = "Error cargando datos: $e";
      debugPrint("Dashboard Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper para superar el límite de 10 en 'whereIn' de Firestore
  Future<List<UserModel>> _fetchUsersInChunks(List<String> allUids) async {
    List<UserModel> users = [];
    // Dividimos en lotes de 10
    for (var i = 0; i < allUids.length; i += 10) {
      final end = (i + 10 < allUids.length) ? i + 10 : allUids.length;
      final chunk = allUids.sublist(i, end);

      final snapshot = await _db.collection('users')
          .where('uid', whereIn: chunk)
          .get();

      users.addAll(snapshot.docs.map((d) => UserModel.fromMap(d.data(), d.id)));
    }
    return users;
  }

  Set<String> _processStatsFromEnrollments(List<QueryDocumentSnapshot> docs) {
    _resetStats();
    final Set<String> uniqueStudents = {};

    // Mapas temporales para cálculo
    final Map<String, Set<String>> studentStatuses = {}; // UID -> {ACREDITADO, NO_ACREDITADO...}

    // Reiniciar mapas de clase
    _periodStatusMap = {};
    _periodAcademyMap = {};
    _academyStudentCounts = {};

    // Map auxiliar para contar alumnos por academia (Academia -> Set<UID>)
    final Map<String, Set<String>> academyUsersSet = {};

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final uid = data['uid'] as String?;
      if (uid == null) continue;

      final status = (data['status'] as String? ?? 'PENDIENTE').toUpperCase();
      final academy = (data['academy'] as String? ?? 'GENERAL').toUpperCase();

      uniqueStudents.add(uid);
      studentStatuses.putIfAbsent(uid, () => {}).add(status);

      // Registrar academia para el alumno
      _periodAcademyMap.putIfAbsent(uid, () => {}).add(academy);

      // Agrupar para conteo de academias
      academyUsersSet.putIfAbsent(academy, () => {}).add(uid);
    }

    _totalStudents = uniqueStudents.length;

    // 1. Calcular Estatus Global por Alumno (Regla de Negocio)
    for (var uid in uniqueStudents) {
      final statuses = studentStatuses[uid]!;
      String finalStatus = 'EN_CURSO'; // Default

      if (statuses.contains('NO_ACREDITADO')) {
        finalStatus = 'NO_ACREDITADO';
        _notAccreditedCount++;
      } else if (statuses.contains('EN_CURSO')) {
        finalStatus = 'EN_CURSO';
        _inCourseCount++;
      } else if (statuses.contains('PRE_REGISTRO')) {
        finalStatus = 'PRE_REGISTRO';
        _preRegCount++;
      } else if (statuses.contains('PENDIENTE') || statuses.contains('PENDIENTE_ASIGNACION')) {
        finalStatus = 'PENDIENTE_ASIGNACION';
        _pendingCount++;
      } else if (statuses.every((s) => s == 'ACREDITADO')) {
        finalStatus = 'ACREDITADO';
        _accreditedCount++;
      } else {
        _inCourseCount++;
      }

      // Guardamos el estatus calculado para usarlo al filtrar la lista
      _periodStatusMap[uid] = finalStatus;
    }

    // 2. Calcular Totales por Academia (Alumnos Únicos)
    academyUsersSet.forEach((academy, uids) {
      _academyStudentCounts[academy] = uids.length;
    });

    return uniqueStudents;
  }

  void _resetStats() {
    _totalStudents = 0;
    _preRegCount = 0;
    _pendingCount = 0;
    _inCourseCount = 0;
    _accreditedCount = 0;
    _notAccreditedCount = 0;
    _academyStudentCounts = {};
  }

  // --- FILTROS PARA NAVEGACIÓN ---

  // Devuelve los alumnos que coinciden con el estatus calculado en ESTE periodo
  List<UserModel> getStudentsByStatus(String targetStatus) {
    // Filtramos la lista cargada usando el mapa de estatus histórico
    return _allPeriodStudents.where((student) {
      final histStatus = _periodStatusMap[student.id];
      return histStatus == targetStatus;
    }).map((s) {
      // TRUCO PRO: Devolvemos una copia del alumno con el estatus "visual" modificado
      // para que en la lista aparezca "NO ACREDITADO" si así estaba en el pasado.
      return s.copyWith(status: targetStatus);
    }).toList();
  }

  List<UserModel> getStudentsByAcademy(String academy) {
    return _allPeriodStudents.where((student) {
      final academies = _periodAcademyMap[student.id] ?? {};
      return academies.contains(academy);
    }).toList();
  }

  Future<void> logout({VoidCallback? onDone}) async {
    await _authRepo.signOut();
    onDone?.call();
  }
}