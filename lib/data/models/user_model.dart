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
  final List<String> subjectsToTake; // <-- NEW

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
    this.subjectsToTake = const [], // <-- NEW
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {

    List<String> parsedAcademies = [];
    if (map['academies'] != null && map['academies'] is Iterable) {
      parsedAcademies = List<String>.from(map['academies']);
    } else if (map['academy'] != null && map['academy'] is String) {
      parsedAcademies = [map['academy']];
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
      subjectsToTake: List<String>.from(map['subjects_to_take'] ?? []), // <-- NEW
    );
  }
}
