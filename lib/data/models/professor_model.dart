class ProfessorModel {
  final String name;
  final String schedule;

  ProfessorModel({required this.name, required this.schedule});

  factory ProfessorModel.fromMap(Map<String, dynamic> map) {
    return ProfessorModel(
      name: map['name'] ?? 'Nombre no disponible',
      schedule: map['schedule'] ?? 'Horario no especificado',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'schedule': schedule,
    };
  }
}
