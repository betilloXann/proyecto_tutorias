import 'package:cloud_firestore/cloud_firestore.dart';

class EnrollmentModel {
  final String id;
  final String uid;
  final String subject;
  final String periodId;
  final String professor;
  final String schedule;
  final String salon;
  final String status;
  final String academy;
  final DateTime assignedAt;
  final double? finalGrade;
  final String? recoveryActUrl;

  EnrollmentModel({
    required this.id,
    required this.uid,
    required this.subject,
    required this.periodId,
    required this.professor,
    required this.schedule,
    required this.salon,
    required this.status,
    required this.academy,
    required this.assignedAt,
    this.finalGrade,
    this.recoveryActUrl,
  });

  /// Calcula el periodId según la fecha
  /// Enero - Junio -> /1
  /// Julio - Diciembre -> /2
  static String getPeriodId(DateTime date) {
    int year = date.year % 100; // últimos 2 dígitos del año
    int semester = (date.month >= 1 && date.month <= 6) ? 1 : 2;
    return '$year/$semester';
  }

  factory EnrollmentModel.fromMap(Map<String, dynamic> data, String documentId) {
    DateTime assignedAt = (data['assigned_at'] as Timestamp?)?.toDate() ?? DateTime.now();

    return EnrollmentModel(
      id: documentId,
      uid: data['uid'] ?? 'N/A',
      subject: data['subject'] ?? 'N/A',
      professor: data['professor'] ?? 'N/A',
      schedule: data['schedule'] ?? 'N/A',
      salon: data['salon'] ?? 'N/A',
      status: data['status'] ?? 'N/A',
      academy: data['academy'] ?? 'N/A',
      assignedAt: assignedAt,
      periodId: getPeriodId(assignedAt),
      finalGrade: (data['final_grade'] != null) ? (data['final_grade'] as num).toDouble() : null,
      recoveryActUrl: data['recovery_act_url'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'subject': subject,
      'professor': professor,
      'schedule': schedule,
      'salon': salon,
      'status': status,
      'academy': academy,
      'assigned_at': Timestamp.fromDate(assignedAt),
      'periodId': periodId,
      'final_grade': finalGrade,
      'recovery_act_url': recoveryActUrl,
    };
  }
}