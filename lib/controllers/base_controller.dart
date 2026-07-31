import 'package:flutter/material.dart';

/// Controller dasar: state loading + error + notifikasi.
class BaseController extends ChangeNotifier {
  bool _loading = false;
  String? _error;

  bool get isLoading => _loading;
  String? get error => _error;

  void setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  void setError(String? value) {
    _error = value;
    notifyListeners();
  }
}
