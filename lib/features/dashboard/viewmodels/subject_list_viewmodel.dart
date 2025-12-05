import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/subject_model.dart';

class SubjectListViewModel extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String currentAcademy = 'SISTEMAS'; // Assuming a static academy for now

  bool _isLoading = true;
  String? _errorMessage;
  List<SubjectModel> _subjects = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<SubjectModel> get subjects => _subjects;

  SubjectListViewModel() {
    loadSubjects();
  }

  Future<void> loadSubjects() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final snapshot = await _db
          .collection('subjects')
          .where('academy', isEqualTo: currentAcademy)
          .get();

      _subjects = snapshot.docs.map((doc) => SubjectModel.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      _errorMessage = "Error al cargar las materias: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
