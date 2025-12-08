import './professor_model.dart';

class SubjectModel {
  final String id;
  final String name;
  final String academy;
  final List<ProfessorModel> professors;

  SubjectModel({
    required this.id,
    required this.name,
    required this.academy,
    this.professors = const [],
  });

  factory SubjectModel.fromMap(Map<String, dynamic> map, String documentId) {
    var professorsList = (map['professors'] as List? ?? [])
        .map((profMap) => ProfessorModel.fromMap(profMap))
        .toList();

    return SubjectModel(
      id: documentId,
      name: map['name'] ?? 'Nombre de materia no disponible',
      academy: map['academy'] ?? 'Sin Academia', // <--- AGREGADO
      professors: professorsList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'academy': academy,
      'professors': professors.map((prof) => prof.toMap()).toList(),
    };
  }
}
