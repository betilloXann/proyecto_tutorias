import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/subject_model.dart';

class SubjectListViewModel extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final List<String> myAcademies;

  bool _isLoading = true;
  String? _errorMessage;
  List<SubjectModel> _subjects = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<SubjectModel> get subjects => _subjects;

  SubjectListViewModel({required this.myAcademies}) {
    loadSubjects();
  }

  Future<void> loadSubjects() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // FIX: Use a 'whereIn' query to search in all the user's academies
      if (myAcademies.isEmpty) {
        _subjects = [];
      } else {
        final snapshot = await _db
            .collection('subjects')
            .where('academy', whereIn: myAcademies)
            .get();
        _subjects = snapshot.docs.map((doc) => SubjectModel.fromMap(doc.data(), doc.id)).toList();
      }
    } catch (e) {
      _errorMessage = "Error al cargar las materias: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
