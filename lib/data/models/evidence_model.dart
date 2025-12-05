import 'package:cloud_firestore/cloud_firestore.dart';

class EvidenceModel {
  final String id;
  final String fileName;
  final String fileUrl;
  final DateTime uploadedAt;
  final String status;
  final String? feedback;
  final String subject; // <-- RESTORED

  EvidenceModel({
    required this.id,
    required this.fileName,
    required this.fileUrl,
    required this.uploadedAt,
    required this.status,
    required this.subject, // <-- RESTORED
    this.feedback,
  });

  factory EvidenceModel.fromMap(Map<String, dynamic> data, String documentId) {
    return EvidenceModel(
      id: documentId,
      fileName: data['file_name'] ?? 'Nombre de archivo no disponible',
      fileUrl: data['file_url'] ?? '',
      uploadedAt: (data['uploaded_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'EN_REVISION',
      feedback: data['feedback'],
      subject: data['materia'] ?? 'Materia Desconocida', // <-- RESTORED
    );
  }
}
