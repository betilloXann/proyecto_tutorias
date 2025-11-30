class UserModel {
  final String id; // ID del documento
  final String boleta;
  final String name;
  final String emailInst;
  final String status; // PRE_REGISTRO, PENDIENTE_ASIGNACION, EN_CURSO...
  final String role;   // student, admin

  UserModel({
    required this.id,
    required this.boleta,
    required this.name,
    this.emailInst = '',
    required this.status,
    required this.role,
  });

  // Convertir de Firestore a Objeto Dart
  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    return UserModel(
      id: docId,
      boleta: map['boleta'] ?? '',
      name: map['name'] ?? '',
      emailInst: map['email_inst'] ?? '',
      status: map['status'] ?? 'PRE_REGISTRO',
      role: map['role'] ?? 'student',
    );
  }
}