import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../models/student_model.dart';

class AuthController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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

  // ── Login com e-mail e senha ─────────────────────────────────────────────
 Future<bool> loginProfessor(String email, String password) async {
  _isLoading = true;
  notifyListeners(); // Avisa o botão para mostrar o loading

  try {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email, 
      password: password
    );
    _isLoading = false;
    notifyListeners();
    return true;
  } catch (e) {
    _isLoading = false;
    notifyListeners();
    print("Erro no login: $e"); // Veja este erro no console do VS Code!
    return false; // Se retornar false, o 'ok' do seu botão será false e não navega
  }
}
  // ── Cadastro com e-mail e senha ──────────────────────────────────────────
  Future<bool> registerProfessor(String name, String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) throw FirebaseAuthException(code: 'null-user');

      // Salva o nome de exibição no perfil Firebase
      await user.updateDisplayName(name.trim());

      _currentUser = UserModel(
        id: user.uid,
        name: name.trim(),
        email: user.email ?? '',
        role: UserRole.professor,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _translateError(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Erro inesperado. Tente novamente.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Login com Google ─────────────────────────────────────────────────────
  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      GoogleAuthCredential? authCredential;

      if (kIsWeb) {
        // Web: usa popup
        final provider = GoogleAuthProvider();
        final result = await _auth.signInWithPopup(provider);
        final user = result.user;
        if (user == null) throw FirebaseAuthException(code: 'null-user');
        _currentUser = UserModel(
          id: user.uid,
          name: user.displayName ?? _nameFromEmail(user.email ?? ''),
          email: user.email ?? '',
          role: UserRole.professor,
        );
        _isLoading = false;
        notifyListeners();
        return true;
      }

      // Mobile (Android / iOS)
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // Usuário cancelou
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      final user = result.user;
      if (user == null) throw FirebaseAuthException(code: 'null-user');

      _currentUser = UserModel(
        id: user.uid,
        name: user.displayName ?? googleUser.displayName ?? _nameFromEmail(user.email ?? ''),
        email: user.email ?? '',
        role: UserRole.professor,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _translateError(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Não foi possível entrar com Google. Tente novamente.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Redefinir senha ──────────────────────────────────────────────────────
  Future<bool> sendPasswordReset(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _translateError(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Login aluno por código de sala ───────────────────────────────────────
  Future<bool> loginWithRoomCode(String roomCode) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));

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

  Future<void> logout() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    _currentUser = null;
    _currentStudent = null;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  String _nameFromEmail(String email) =>
      email.split('@').first.replaceAll(RegExp(r'[._]'), ' ');

  String _translateError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Nenhuma conta encontrada com este e-mail.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-mail ou senha incorretos.';
      case 'email-already-in-use':
        return 'Este e-mail já está cadastrado.';
      case 'weak-password':
        return 'Senha muito fraca. Use ao menos 6 caracteres.';
      case 'invalid-email':
        return 'E-mail inválido.';
      case 'too-many-requests':
        return 'Muitas tentativas. Aguarde um momento e tente novamente.';
      case 'network-request-failed':
        return 'Sem conexão com a internet.';
      case 'user-disabled':
        return 'Esta conta foi desativada.';
      default:
        return 'Erro de autenticação. Tente novamente.';
    }
  }
}
