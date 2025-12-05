class UserModel {
  final String id;
  final String boleta;
  final String name;
  final String email;
  final String status;
  final String role;
  final String academy;
  final String? dictamenUrl;
  final double? finalGrade; // <-- ADDED

  UserModel({
    required this.id,
    required this.boleta,
    required this.name,
    required this.email,
    required this.status,
    required this.role,
    required this.academy,
    this.dictamenUrl,
    this.finalGrade,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    return UserModel(
      id: docId,
      boleta: map['boleta'] ?? '',
      name: map['name'] ?? '',
      email: map['email_inst'] ?? 'No especificado',
      status: map['status'] ?? 'PRE_REGISTRO',
      role: map['role'] ?? 'student',
      academy: map['academy'] ?? 'N/A',
      dictamenUrl: map['dictamen_url'],
      finalGrade: (map['final_grade'] as num?)?.toDouble(), // <-- ADDED
    );
  }
}
