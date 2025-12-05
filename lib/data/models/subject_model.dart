import './professor_model.dart';

class SubjectModel {
  final String id;
  final String name;
  final List<ProfessorModel> professors;

  SubjectModel({
    required this.id,
    required this.name,
    this.professors = const [],
  });

  factory SubjectModel.fromMap(Map<String, dynamic> map, String documentId) {
    var professorsList = (map['professors'] as List? ?? [])
        .map((profMap) => ProfessorModel.fromMap(profMap))
        .toList();

    return SubjectModel(
      id: documentId,
      name: map['name'] ?? 'Nombre de materia no disponible',
      professors: professorsList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'professors': professors.map((prof) => prof.toMap()).toList(),
    };
  }
}
