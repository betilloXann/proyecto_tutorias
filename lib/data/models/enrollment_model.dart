class EnrollmentModel {
  final String id;
  final String studentUid;
  final String subject;
  final String professor;
  final String schedule;
  final String salon;

  EnrollmentModel({
    required this.id,
    required this.studentUid,
    required this.subject,
    required this.professor,
    required this.schedule,
    required this.salon,
  });

  factory EnrollmentModel.fromMap(Map<String, dynamic> map, String docId) {
    return EnrollmentModel(
      id: docId,
      studentUid: map['uid'] ?? '',
      subject: map['subject'] ?? 'Materia desconocida',
      professor: map['professor'] ?? 'Por asignar',
      schedule: map['schedule'] ?? 'Por definir',
      salon: map['salon'] ?? 'Sin asignar',
    );
  }
}