class ProfessorModel {
  final String? uid; // ID del usuario en Firebase (NUEVO)
  final String name;
  final String? email; // Correo para contacto/login (NUEVO)
  final String schedule; // Horario en esta materia específica

  ProfessorModel({
    this.uid,
    required this.name,
    this.email,
    required this.schedule
  });

  factory ProfessorModel.fromMap(Map<String, dynamic> map) {
    return ProfessorModel(
      uid: map['uid'],
      name: map['name'] ?? 'Nombre no disponible',
      email: map['email'],
      schedule: map['schedule'] ?? 'Horario no especificado',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'schedule': schedule,
    };
  }
}