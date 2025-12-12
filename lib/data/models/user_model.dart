class UserModel {
  final String id;
  final String boleta;
  final String name;
  final String email;
  final String status;
  final String role;
  final List<String> academies;
  final String? dictamenUrl;
  final double? finalGrade;
  final List<String> subjectsToTake;
  final Map<String, String> academyStatus;

  UserModel({
    required this.id,
    required this.boleta,
    required this.name,
    required this.email,
    required this.status,
    required this.role,
    required this.academies,
    this.dictamenUrl,
    this.finalGrade,
    this.subjectsToTake = const [],
    this.academyStatus = const {}, // <-- Inicializar vacío por defecto
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    List<String> parsedAcademies = [];
    if (map['academies'] != null && map['academies'] is Iterable) {
      parsedAcademies = List<String>.from(map['academies']);
    } else if (map['academy'] != null && map['academy'] is String) {
      parsedAcademies = [map['academy']];
    }

    // --- LÓGICA DE MIGRACIÓN / PARSEO ---
    // Si existe el mapa detallado en BD, lo usamos.
    // Si no, construimos uno por defecto usando el estatus global para todas sus academias.
    Map<String, String> parsedAcademyStatus = {};
    if (map['academy_status'] != null && map['academy_status'] is Map) {
      parsedAcademyStatus = Map<String, String>.from(map['academy_status']);
    } else {
      // Si es un alumno antiguo sin mapa, usamos el estatus global como fallback para sus academias
      final globalStatus = map['status'] ?? 'PENDIENTE_ASIGNACION';
      for (var academy in parsedAcademies) {
        parsedAcademyStatus[academy] = globalStatus;
      }
    }

    return UserModel(
      id: docId,
      boleta: map['boleta'] ?? '',
      name: map['name'] ?? '',
      email: map['email_inst'] ?? 'No especificado',
      status: map['status'] ?? 'PRE_REGISTRO',
      role: map['role'] ?? 'student',
      academies: parsedAcademies,
      dictamenUrl: map['dictamen_url'],
      finalGrade: (map['final_grade'] as num?)?.toDouble(),
      subjectsToTake: List<String>.from(map['subjects_to_take'] ?? []),
      academyStatus: parsedAcademyStatus, // <-- NUEVO
    );
  }

  // Helper para obtener estatus seguro de una academia específica
  String getStatusForAcademy(String academy) {
    return academyStatus[academy] ?? status;
  }
}