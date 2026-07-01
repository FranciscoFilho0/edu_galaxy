import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/student_model.dart';

class AuthController extends ChangeNotifier {
  UserModel? _currentUser;
  StudentModel? _currentStudent;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  StudentModel? get currentStudent => _currentStudent;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null || _currentStudent != null;
  bool get isProfessor => _currentUser?.role == UserRole.professor;

  // Simulated professor login
  Future<bool> loginProfessor(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    // Mock validation
    if (email.isNotEmpty && password.length >= 6) {
      _currentUser = UserModel(
        id: 'prof_001',
        name: 'Prof. ${email.split('@').first}',
        email: email,
        role: UserRole.professor,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _errorMessage = 'Email ou senha inválidos.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Simulated student room code login
  Future<bool> loginWithRoomCode(String roomCode) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    if (roomCode.length == 6) {
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _errorMessage = 'Código de sala inválido. Use 6 dígitos.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void setStudentProfile(StudentModel student) {
    _currentStudent = student;
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    _currentStudent = null;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
