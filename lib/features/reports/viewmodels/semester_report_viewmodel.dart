import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/enrollment_model.dart';
import '../../../data/models/user_model.dart';
// Eliminé la importación de AuthRepository porque ya no se usa
// import '../../../data/repositories/auth_repository.dart'; 

// Para la generación de Excel
import 'package:universal_html/html.dart' as html;
import 'package:excel/excel.dart';

// Definiendo un tipo para las estadísticas
typedef Stats = ({int accredited, int notAccredited});

class SemesterReportViewModel extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  // Eliminado: final AuthRepository _authRepo;

  bool _isLoading = false;
  String? _loadingMessage;
  String? _errorMessage;

  // --- DATOS PARA GRÁFICOS ---
  Map<String, Stats> _accreditedBySubject = {};
  Map<String, Stats> _accreditedByAcademy = {};

  bool get isLoading => _isLoading;
  String? get loadingMessage => _loadingMessage;
  String? get errorMessage => _errorMessage;

  Map<String, Stats> get accreditedBySubject => _accreditedBySubject;
  Map<String, Stats> get accreditedByAcademy => _accreditedByAcademy;

  // --- CONSTRUCTOR CORREGIDO ---
  // Ya no pedimos 'authRepo' porque no lo usamos
  SemesterReportViewModel(); 

  void _setLoading(bool loading, [String? message]) {
    _isLoading = loading;
    _loadingMessage = message;
    notifyListeners();
  }

  // --- FUNCIÓN PRIVADA PARA OBTENER DATOS ---
  Future<({List<UserModel> students, Map<String, List<EnrollmentModel>> enrollments})> _fetchReportData() async {
    _setLoading(true, "Obteniendo datos de alumnos...");
    
    // ROL TUTORIAS: Obtiene todos los alumnos sin filtrar por academia
    final studentsSnapshot = await _db.collection('users')
        .where('role', isEqualTo: 'student')
        .get();

    final students = studentsSnapshot.docs.map((doc) => UserModel.fromMap(doc.data(), doc.id)).toList();
    final studentIds = students.map((s) => s.id).toList();

    if (studentIds.isEmpty) {
      return (students: <UserModel>[], enrollments: <String, List<EnrollmentModel>>{});
    }

    _setLoading(true, "Obteniendo inscripciones...");
    final Map<String, List<EnrollmentModel>> allEnrollments = {};
    
    // Firestore 'whereIn' solo soporta hasta 10 elementos, por eso procesamos en lotes
    for (int i = 0; i < studentIds.length; i += 10) {
      final chunk = studentIds.sublist(i, i + 10 > studentIds.length ? studentIds.length : i + 10);
      final enrollmentsSnapshot = await _db.collection('enrollments').where('uid', whereIn: chunk).get();

      for (final doc in enrollmentsSnapshot.docs) {
        final enrollment = EnrollmentModel.fromMap(doc.data(), doc.id);
        allEnrollments.putIfAbsent(enrollment.uid, () => []).add(enrollment);
      }
    }
    return (students: students, enrollments: allEnrollments);
  }

  // --- LÓGICA PARA GRÁFICOS ---
  Future<void> processChartData() async {
    _setLoading(true, "Procesando datos para gráficos...");
    _errorMessage = null;

    try {
      final data = await _fetchReportData();
      if (data.students.isEmpty) {
        _accreditedBySubject = {};
        _accreditedByAcademy = {};
        notifyListeners();
        return;
      }

      final tempBySubject = <String, Stats>{};
      final tempByAcademy = <String, Stats>{};

      for (final student in data.students) {
        final studentEnrollments = data.enrollments[student.id] ?? [];
        for (final enrollment in studentEnrollments) {
          if (enrollment.status == 'ACREDITADO' || enrollment.status == 'NO_ACREDITADO') {
            
            // Conteo por materia
            final subjectStat = tempBySubject.putIfAbsent(enrollment.subject, () => (accredited: 0, notAccredited: 0));
            if (enrollment.status == 'ACREDITADO') {
              tempBySubject[enrollment.subject] = (accredited: subjectStat.accredited + 1, notAccredited: subjectStat.notAccredited);
            } else {
              tempBySubject[enrollment.subject] = (accredited: subjectStat.accredited, notAccredited: subjectStat.notAccredited + 1);
            }

            // Conteo por academia
            final academyStat = tempByAcademy.putIfAbsent(enrollment.academy, () => (accredited: 0, notAccredited: 0));
             if (enrollment.status == 'ACREDITADO') {
              tempByAcademy[enrollment.academy] = (accredited: academyStat.accredited + 1, notAccredited: academyStat.notAccredited);
            } else {
              tempByAcademy[enrollment.academy] = (accredited: academyStat.accredited, notAccredited: academyStat.notAccredited + 1);
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
    _setLoading(true, "Generando reporte...");
    _errorMessage = null;

    try {
      final data = await _fetchReportData();
      if (data.students.isEmpty) {
        throw Exception("No hay alumnos para reportar.");
      }

      _setLoading(true, "Creando archivo Excel...");
      final excel = Excel.createExcel();
      final Sheet sheet = excel[excel.getDefaultSheet()!];

      final headers = ['Boleta', 'Nombre del Alumno', 'Materia', 'Estatus', 'Calificación'];
      sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

      for (final student in data.students) {
        final studentEnrollments = data.enrollments[student.id] ?? [];
        if (studentEnrollments.isEmpty) {
          sheet.appendRow([TextCellValue(student.boleta), TextCellValue(student.name), TextCellValue('-'), TextCellValue('Sin materias'), TextCellValue('-')]);
        } else {
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

      final fileBytes = excel.save();
      if (fileBytes != null && kIsWeb) {
        final blob = html.Blob([fileBytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute("download", "Reporte_Fin_Semestre.xlsx")
          ..click();
        html.Url.revokeObjectUrl(url);
      } else if (!kIsWeb) {
        throw Exception("La descarga de archivos solo está soportada en la versión web.");
      }

    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception: ", "");
    } finally {
      _setLoading(false);
    }
  }

  // --- LÓGICA DE LIMPIEZA ---
  Future<String?> deleteAllStudents() async {
    _setLoading(true, "Eliminando TODOS los alumnos...");
    _errorMessage = null;

    try {
      final batch = _db.batch();
      final snapshot = await _db.collection('users').where('role', isEqualTo: 'student').get();

      if (snapshot.docs.isEmpty) {
        return "No hay alumnos para eliminar.";
      }

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      return "${snapshot.docs.length} alumnos han sido eliminados.";
    } catch (e) {
      _errorMessage = "Error al eliminar alumnos: $e";
      return null;
    } finally {
      _setLoading(false);
    }
  }
}