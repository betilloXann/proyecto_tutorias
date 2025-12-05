import 'package:cloud_firestore/cloud_firestore.dart';

class EnrollmentModel {
  final String id;
  final String subject;
  final String professor;
  final String schedule;
  final String salon;
  final String status;
  final DateTime assignedAt;

  EnrollmentModel({
    required this.id,
    required this.subject,
    required this.professor,
    required this.schedule,
    required this.salon,
    required this.status,
    required this.assignedAt,
  });

  // Factory constructor to create an instance from a Firestore document
  factory EnrollmentModel.fromMap(Map<String, dynamic> data, String documentId) {
    return EnrollmentModel(
      id: documentId,
      subject: data['subject'] ?? 'N/A',
      professor: data['professor'] ?? 'N/A',
      schedule: data['schedule'] ?? 'N/A',
      salon: data['salon'] ?? 'N/A',
      status: data['status'] ?? 'N/A',
      assignedAt: (data['assigned_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
