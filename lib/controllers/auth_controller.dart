import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/student_model.dart';
import '../services/firestore_service.dart';

class AuthController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirestoreService _db = FirestoreService.instance;

  // Chaves usadas para salvar a sessão do ALUNO no armazenamento local do
  // aparelho (o professor não precisa disso — o pacote firebase_auth já
  // guarda a sessão dele sozinho, ver `tryAutoLogin` mais abaixo).
  static const String _kStudentProfessorIdKey = 'session_student_professorId';
  static const String _kStudentIdKey = 'session_student_id';

  UserModel? _currentUser;
  StudentModel? _currentStudent;
  bool _isLoading = false;
  // Fica true só durante a checagem inicial (tryAutoLogin), enquanto a
  // splash screen decide para onde mandar o usuário.
  bool _isRestoringSession = true;
  String? _errorMessage;

  // Dados temporários guardados entre a tela de "código da turma" e a tela
  // de "criar perfil do aluno" (ainda não temos um StudentModel completo
  // nesse meio-tempo, só sabemos a qual professor a sala pertence).
  String? _pendingProfessorId;
  String? _pendingProfessorName;
  String? _pendingRoomCode;
  // Lista de alunos que o PROFESSOR já cadastrou nessa sala. É contra essa
  // lista que validamos o nome digitado na tela seguinte — o aluno só
  // consegue entrar se o professor já tiver cadastrado ele antes.
  List<StudentModel> _pendingRoomStudents = [];

  UserModel? get currentUser => _currentUser;
  StudentModel? get currentStudent => _currentStudent;
  bool get isLoading => _isLoading;
  bool get isRestoringSession => _isRestoringSession;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null || _currentStudent != null;
  bool get isProfessor => _currentUser?.role == UserRole.professor;

  String? get pendingProfessorId => _pendingProfessorId;
  String? get pendingProfessorName => _pendingProfessorName;
  String? get pendingRoomCode => _pendingRoomCode;
  List<StudentModel> get pendingRoomStudents => _pendingRoomStudents;

  // ── Restaurar sessão salva (chamado uma vez, na splash screen) ──────────
  /// O professor não precisa de nada especial aqui: o pacote firebase_auth
  /// JÁ mantém o login salvo sozinho entre uma abertura e outra do app
  /// (isso se chama "persistência", e é o comportamento padrão dele). Então
  /// só perguntamos pra ele "quem está logado agora?".
  ///
  /// Já o aluno não tem conta de e-mail/senha — ele "loga" digitando o
  /// código da sala e o nome. Não existe nada pronto que lembre disso
  /// sozinho, então SOMOS NÓS que salvamos o id do professor + id do aluno
  /// no armazenamento local (SharedPreferences) quando ele entra, e
  /// buscamos de novo aqui.
  Future<void> tryAutoLogin() async {
    _isRestoringSession = true;
    notifyListeners();

    try {
      final fbUser = _auth.currentUser;

      // Caso 1: existe um usuário do Firebase Auth logado e NÃO é anônimo
      // (login anônimo é só o "truque técnico" usado pelo aluno para poder
      // ler o Firestore — não conta como professor logado).
      if (fbUser != null && !fbUser.isAnonymous) {
        _currentUser = UserModel(
          id: fbUser.uid,
          name: fbUser.displayName ?? _nameFromEmail(fbUser.email ?? ''),
          email: fbUser.email ?? '',
          role: UserRole.professor,
        );
        await _db.getOrCreateRoom(professorId: fbUser.uid, professorName: _currentUser!.name);
        _isRestoringSession = false;
        notifyListeners();
        return;
      }

      // Caso 2: procura uma sessão de aluno salva localmente.
      final prefs = await SharedPreferences.getInstance();
      final savedProfessorId = prefs.getString(_kStudentProfessorIdKey);
      final savedStudentId = prefs.getString(_kStudentIdKey);

      if (savedProfessorId != null && savedStudentId != null) {
        // Garante o login anônimo de novo, caso o app tenha sido reaberto
        // sem nenhuma sessão do Firebase Auth ativa (ex: cache limpo).
        if (_auth.currentUser == null) {
          await _auth.signInAnonymously();
        }

        final students = await _db.fetchStudents(savedProfessorId);
        StudentModel? match;
        for (final s in students) {
          if (s.id == savedStudentId) {
            match = s;
            break;
          }
        }

        if (match != null) {
          _currentStudent = match;
        } else {
          // O professor pode ter removido o aluno da turma nesse meio
          // tempo — nesse caso não faz sentido manter a sessão salva.
          await prefs.remove(_kStudentProfessorIdKey);
          await prefs.remove(_kStudentIdKey);
        }
      }
    } catch (e) {
      debugPrint('Erro ao restaurar sessão: $e');
    }

    _isRestoringSession = false;
    notifyListeners();
  }

  // ── Login com e-mail e senha ─────────────────────────────────────────────
  Future<bool> loginProfessor(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) throw FirebaseAuthException(code: 'null-user');

      _currentUser = UserModel(
        id: user.uid,
        name: user.displayName ?? _nameFromEmail(user.email ?? ''),
        email: user.email ?? '',
        role: UserRole.professor,
      );

      // Garante que a sala desse professor existe (se já existir, só a reaproveita).
      await _db.getOrCreateRoom(professorId: user.uid, professorName: _currentUser!.name);

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _translateError(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('Erro no login: $e');
      return false;
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

      await user.updateDisplayName(name.trim());

      _currentUser = UserModel(
        id: user.uid,
        name: name.trim(),
        email: user.email ?? '',
        role: UserRole.professor,
      );

      // Cria a sala já no cadastro, com um código único gerado na hora.
      await _db.getOrCreateRoom(professorId: user.uid, professorName: _currentUser!.name);

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
      if (kIsWeb) {
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
        await _db.getOrCreateRoom(professorId: user.uid, professorName: _currentUser!.name);
        _isLoading = false;
        notifyListeners();
        return true;
      }

      // Mobile (Android / iOS)
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
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
      await _db.getOrCreateRoom(professorId: user.uid, professorName: _currentUser!.name);

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
  /// Agora consulta o Firestore de verdade: só passa se o código pertencer
  /// a uma sala existente. Guarda o professorId encontrado para usarmos na
  /// tela seguinte (criação do perfil do aluno).
  Future<bool> loginWithRoomCode(String roomCode) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final code = roomCode.trim().toUpperCase();
    if (code.length != 6) {
      _errorMessage = 'Código de sala inválido. Use 6 dígitos.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      // O aluno não faz login com e-mail/senha nem Google, mas o Firestore
      // (com as regras de segurança recomendadas) só permite leitura para
      // usuários autenticados. Por isso, garantimos um login anônimo antes
      // de consultar o código da sala. Isso não cria conta "de verdade":
      // é só um UID técnico do Firebase Auth para satisfazer as regras.
      if (_auth.currentUser == null) {
        await _auth.signInAnonymously();
      }

      final room = await _db.resolveRoomByCode(code);
      if (room == null) {
        _errorMessage = 'Não encontramos nenhuma turma com esse código.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final professorId = room['professorId']!;

      // Só deixamos passar se o professor já tiver cadastrado pelo menos
      // um aluno nessa turma. Isso evita que qualquer pessoa com o código
      // entre sem estar na lista do professor.
      final students = await _db.fetchStudents(professorId);
      if (students.isEmpty) {
        _errorMessage = 'Essa turma ainda não tem alunos cadastrados. Peça ao seu professor para te cadastrar antes de entrar.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _pendingProfessorId = professorId;
      _pendingProfessorName = room['professorName'];
      _pendingRoomCode = room['code'];
      _pendingRoomStudents = students;

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('Erro (FirebaseAuth) ao verificar código de sala: ${e.code} - ${e.message}');
      _errorMessage = 'Erro ao verificar o código. Tente novamente.';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      // Deixamos o erro real no log (visível no terminal/Logcat) para
      // facilitar o diagnóstico, mesmo mostrando uma mensagem amigável
      // para o aluno.
      debugPrint('Erro ao verificar código de sala: $e');
      _errorMessage = 'Erro ao verificar o código. Tente novamente.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }


  /// Confirma a entrada do aluno na turma. NÃO cria nenhum aluno novo —
  /// só permite continuar se o nome digitado bater com um aluno que o
  /// PROFESSOR já cadastrou nessa sala (comparação sem diferenciar
  /// maiúsculas/minúsculas e ignorando espaços extras).
  Future<bool> registerStudentProfile({
    required String name,
    required String avatarIndex,
  }) async {
    if (_pendingProfessorId == null || _pendingRoomCode == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final typedName = name.trim().toLowerCase();

    StudentModel? match;
    for (final s in _pendingRoomStudents) {
      if (s.name.trim().toLowerCase() == typedName) {
        match = s;
        break;
      }
    }

    if (match == null) {
      _errorMessage = 'Não encontramos esse nome na turma. Confira com seu professor se ele já te cadastrou (com o mesmo nome).';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      // Guarda o avatar escolhido no registro que o professor já criou.
      await FirestoreService.instance.updateStudentAvatar(
        professorId: _pendingProfessorId!,
        studentId: match.id,
        avatarIndex: avatarIndex,
      );
      _currentStudent = match.copyWith(avatarIndex: avatarIndex);

      // Salva localmente para o próximo tryAutoLogin() reconhecer esse
      // aluno sem precisar pedir o código da sala e o nome de novo.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kStudentProfessorIdKey, _pendingProfessorId!);
      await prefs.setString(_kStudentIdKey, match.id);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erro ao entrar na turma: $e');
      _errorMessage = 'Erro ao entrar na turma. Tente novamente.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    await _googleSignIn.signOut();

    // Apaga a sessão de aluno salva localmente — é isso que garante que
    // "sair" (logout) realmente exige login de novo, diferente de só
    // fechar o app.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kStudentProfessorIdKey);
    await prefs.remove(_kStudentIdKey);

    _currentUser = null;
    _currentStudent = null;
    _pendingProfessorId = null;
    _pendingProfessorName = null;
    _pendingRoomCode = null;
    _pendingRoomStudents = [];
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
