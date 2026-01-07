import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/enrollment_model.dart';
import '../../../data/models/user_model.dart';

// Para la generación de Excel
import 'package:universal_html/html.dart' as html;
import 'package:excel/excel.dart';

typedef Stats = ({int accredited, int notAccredited, int inProgress});

class SemesterReportViewModel extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _isLoading = false;
  String? _loadingMessage;
  String? _errorMessage;

  // --- CONTROL DE PERIODOS ---
  late String _selectedPeriod; // Ej: "26/1"
  List<String> _availablePeriods = [];

  // --- DATOS PARA GRÁFICOS ---
  Map<String, Stats> _accreditedBySubject = {};
  Map<String, Stats> _accreditedByAcademy = {};

  // Getters
  bool get isLoading => _isLoading;
  String? get loadingMessage => _loadingMessage;
  String? get errorMessage => _errorMessage;
  String get selectedPeriod => _selectedPeriod;
  List<String> get availablePeriods => _availablePeriods;

  Map<String, Stats> get accreditedBySubject => _accreditedBySubject;
  Map<String, Stats> get accreditedByAcademy => _accreditedByAcademy;

  SemesterReportViewModel() {
    _initializePeriods();
  }

  Future<void> _initializePeriods() async {
    _setLoading(true, "Sincronizando periodo...");

    // 1. Intentar leer la configuración global primero
    try {
      final doc = await _db.collection('config').doc('system_settings').get();

      if (doc.exists && doc.data()!.containsKey('currentPeriod')) {
        _selectedPeriod = doc.data()!['currentPeriod'];
      } else {
        // Fallback a la fecha si no hay config
        _selectedPeriod = EnrollmentModel.getPeriodId(DateTime.now());
      }
    } catch (e) {
      _selectedPeriod = EnrollmentModel.getPeriodId(DateTime.now());
    }

    // 2. Generar lista de periodos (basado en lo que recuperamos, NO en DateTime.now)
    _availablePeriods = [];

    // Parseamos el periodo actual (Ej: "26/1")
    final parts = _selectedPeriod.split('/');
    int currentYear = int.parse(parts[0]);
    int currentSemester = int.parse(parts[1]);

    // Generamos este y los 3 anteriores
    for (int i = 0; i < 4; i++) {
      _availablePeriods.add('$currentYear/$currentSemester');

      // Retroceder un semestre
      if (currentSemester == 1) {
        currentSemester = 2;
        currentYear--; // Si estamos en Ene-Jun, el anterior es Jul-Dic del año pasado
      } else {
        currentSemester = 1; // Si estamos en Jul-Dic, el anterior es Ene-Jun del mismo año
      }
    }

    _setLoading(false); // Termina la carga inicial
    notifyListeners();

    // Opcional: Cargar los gráficos automáticamente al iniciar
    processChartData();
  }

  // 2. Función para cambiar el periodo desde el Dropdown
  void changePeriod(String newPeriod) {
    _selectedPeriod = newPeriod;
    notifyListeners();
    processChartData(); // Recargar datos con el nuevo filtro
  }

  void _setLoading(bool loading, [String? message]) {
    _isLoading = loading;
    _loadingMessage = message;
    notifyListeners();
  }

  // --- FUNCIÓN PRIVADA PARA OBTENER DATOS (FILTRADO POR PERIODO) ---
  Future<({List<UserModel> students, Map<String, List<EnrollmentModel>> enrollments})> _fetchReportData() async {
    _setLoading(true, "Obteniendo datos del periodo $_selectedPeriod...");

    // 1. Obtenemos alumnos (estos siempre son los mismos, el filtro está en sus materias)
    final studentsSnapshot = await _db.collection('users')
        .where('role', isEqualTo: 'student')
        .get();

    final students = studentsSnapshot.docs.map((doc) => UserModel.fromMap(doc.data(), doc.id)).toList();
    final studentIds = students.map((s) => s.id).toList();

    if (studentIds.isEmpty) {
      return (students: <UserModel>[], enrollments: <String, List<EnrollmentModel>>{});
    }

    _setLoading(true, "Filtrando inscripciones...");
    final Map<String, List<EnrollmentModel>> allEnrollments = {};

    // 2. APLICAMOS EL FILTRO: Solo traer materias del '_selectedPeriod'
    for (int i = 0; i < studentIds.length; i += 10) {
      final chunk = studentIds.sublist(i, i + 10 > studentIds.length ? studentIds.length : i + 10);

      final enrollmentsSnapshot = await _db.collection('enrollments')
          .where('uid', whereIn: chunk)
          .where('periodId', isEqualTo: _selectedPeriod)
          .get();

      for (final doc in enrollmentsSnapshot.docs) {
        final enrollment = EnrollmentModel.fromMap(doc.data(), doc.id);
        allEnrollments.putIfAbsent(enrollment.uid, () => []).add(enrollment);
      }
    }
    return (students: students, enrollments: allEnrollments);
  }

  // --- LÓGICA PARA GRÁFICOS ---
  Future<void> processChartData() async {
    _setLoading(true, "Procesando gráficos...");
    _errorMessage = null;

    try {
      final data = await _fetchReportData();

      // Limpiamos datos previos
      _accreditedBySubject = {};
      _accreditedByAcademy = {};

      if (data.students.isEmpty) {
        notifyListeners();
        return;
      }

      final tempBySubject = <String, Stats>{};
      final tempByAcademy = <String, Stats>{};

      for (final student in data.students) {
        final studentEnrollments = data.enrollments[student.id] ?? [];
        for (final enrollment in studentEnrollments) {

          final status = enrollment.status.toUpperCase();

          if (['ACREDITADO', 'NO_ACREDITADO', 'EN_CURSO'].contains(status)) {

            // Conteo por materia
            final subjectStat = tempBySubject.putIfAbsent(enrollment.subject,
                    () => (accredited: 0, notAccredited: 0, inProgress: 0));

            final academyStat = tempByAcademy.putIfAbsent(enrollment.academy,
                    () => (accredited: 0, notAccredited: 0, inProgress: 0));

            // Actualizar contadores según estatus
            if (status == 'ACREDITADO') {
              tempBySubject[enrollment.subject] = (
              accredited: subjectStat.accredited + 1,
              notAccredited: subjectStat.notAccredited,
              inProgress: subjectStat.inProgress
              );
              tempByAcademy[enrollment.academy] = (
              accredited: academyStat.accredited + 1,
              notAccredited: academyStat.notAccredited,
              inProgress: academyStat.inProgress
              );
            } else if (status == 'NO_ACREDITADO') {
              tempBySubject[enrollment.subject] = (
              accredited: subjectStat.accredited,
              notAccredited: subjectStat.notAccredited + 1,
              inProgress: subjectStat.inProgress
              );
              tempByAcademy[enrollment.academy] = (
              accredited: academyStat.accredited,
              notAccredited: academyStat.notAccredited + 1,
              inProgress: academyStat.inProgress
              );
            } else if (status == 'EN_CURSO') {
              tempBySubject[enrollment.subject] = (
              accredited: subjectStat.accredited,
              notAccredited: subjectStat.notAccredited,
              inProgress: subjectStat.inProgress + 1
              );
              tempByAcademy[enrollment.academy] = (
              accredited: academyStat.accredited,
              notAccredited: academyStat.notAccredited,
              inProgress: academyStat.inProgress + 1
              );
            }
          }
        }
      }
      _accreditedBySubject = tempBySubject;
      _accreditedByAcademy = tempByAcademy;

    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception: ", "");
    } finally {
      _setLoading(false);
    }
  }

  // --- LÓGICA PARA EXCEL ---
  Future<void> generateExcelReport() async {
    _setLoading(true, "Generando reporte Excel...");
    _errorMessage = null;

    try {
      final data = await _fetchReportData();

      if (data.students.isEmpty) {
        throw Exception("No hay alumnos registrados.");
      }

      _setLoading(true, "Creando archivo...");
      final excel = Excel.createExcel();
      final Sheet sheet = excel[excel.getDefaultSheet()!];

      sheet.appendRow([TextCellValue('REPORTE PERIODO: $_selectedPeriod')]);
      final headers = ['Boleta', 'Nombre del Alumno', 'Materia', 'Estatus', 'Calificación'];
      sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

      bool dataFound = false;

      for (final student in data.students) {
        final studentEnrollments = data.enrollments[student.id] ?? [];

        if (studentEnrollments.isNotEmpty) {
          dataFound = true;
          for (final enrollment in studentEnrollments) {
            sheet.appendRow([
              TextCellValue(student.boleta),
              TextCellValue(student.name),
              TextCellValue(enrollment.subject),
              TextCellValue(enrollment.status),
              TextCellValue(enrollment.finalGrade?.toString() ?? 'N/A'),
            ]);
          }
        }
      }

      if (!dataFound) {
        throw Exception("No se encontraron registros académicos en el periodo $_selectedPeriod.");
      }

      final fileBytes = excel.save();
      if (fileBytes != null && kIsWeb) {
        final blob = html.Blob([fileBytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute("download", "Reporte_$_selectedPeriod.xlsx")
          ..click();
        html.Url.revokeObjectUrl(url);
      } else if (!kIsWeb) {
        throw Exception("Descarga solo disponible en Web.");
      }

    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception: ", "");
    } finally {
      _setLoading(false);
    }
  }

  // --- CIERRE DE CICLO ---
  Future<String?> closeSemester() async {
    _setLoading(true, "Cerrando ciclo escolar $_selectedPeriod...");
    _errorMessage = null;

    try {
      final parts = _selectedPeriod.split('/');
      int year = int.parse(parts[0]);
      int sem = int.parse(parts[1]);

      String nextPeriod;
      if (sem == 1) {
        nextPeriod = "$year/2";
      } else {
        nextPeriod = "${year + 1}/1";
      }

      await _db.collection('config').doc('system_settings').set({
        'currentPeriod': nextPeriod,
        'previousPeriod': _selectedPeriod,
        'archivedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _selectedPeriod = nextPeriod;
      _initializePeriods(); // Regenerar lista para el nuevo periodo

      notifyListeners();
      return "Ciclo cerrado con éxito. Nuevo periodo activo: $nextPeriod";
    } catch (e) {
      _errorMessage = "Error al cerrar ciclo: $e";
      return null;
    } finally {
      _setLoading(false);
    }
  }
}