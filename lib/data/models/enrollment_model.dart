import 'package:cloud_firestore/cloud_firestore.dart';

class EnrollmentModel {
  final String id;
  final String uid; // <-- AÑADIDO
  final String subject;
  final String professor;
  final String schedule;
  final String salon;
  final String status;
  final String academy; // <-- AÑADIDO
  final DateTime assignedAt;
  final double? finalGrade;

  EnrollmentModel({
    required this.id,
    required this.uid, // <-- AÑADIDO
    required this.subject,
    required this.professor,
    required this.schedule,
    required this.salon,
    required this.status,
    required this.academy, // <-- AÑADIDO
    required this.assignedAt,
    this.finalGrade,
  });

  factory EnrollmentModel.fromMap(Map<String, dynamic> data, String documentId) {
    return EnrollmentModel(
      id: documentId,
      uid: data['uid'] ?? 'N/A', // <-- AÑADIDO
      subject: data['subject'] ?? 'N/A',
      professor: data['professor'] ?? 'N/A',
      schedule: data['schedule'] ?? 'N/A',
      salon: data['salon'] ?? 'N/A',
      status: data['status'] ?? 'N/A',
      academy: data['academy'] ?? 'N/A', // <-- AÑADIDO
      assignedAt: (data['assigned_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      finalGrade: (data['final_grade'] != null) ? (data['final_grade'] as num).toDouble() : null,
    );
  }
}
