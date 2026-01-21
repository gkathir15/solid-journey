import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../model/attraction.dart';

enum ModelStatus { local, notDownloaded, downloading }

class HomeViewModel extends ChangeNotifier {
  ModelStatus _modelStatus = ModelStatus.notDownloaded;
  List<Attraction> _allAttractions = [];
  List<Attraction> _filteredAttractions = [];
  bool _isLoading = false;

  ModelStatus get modelStatus => _modelStatus;
  List<Attraction> get filteredAttractions => _filteredAttractions;
  bool get isLoading => _isLoading;

  HomeViewModel() {
    _loadAttractions();
  }

  Future<void> _loadAttractions() async {
    final String jsonString = await rootBundle.loadString('assets/data/paris_attractions.json');
    final List<dynamic> jsonList = json.decode(jsonString);
    _allAttractions = jsonList.map((json) => Attraction.fromJson(json)).toList();
    _filteredAttractions = _allAttractions;
    notifyListeners();
  }

  void setModelStatus(ModelStatus status) {
    _modelStatus = status;
    notifyListeners();
  }

  void setFilteredAttractions(List<Attraction> attractions) {
    _filteredAttractions = attractions;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  List<Attraction> get allAttractions => _allAttractions;
}
