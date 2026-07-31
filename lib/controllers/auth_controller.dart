import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../models/student_model.dart';
import '../models/room_model.dart';

import '../services/firestore_service.dart';


class AuthController extends ChangeNotifier {


  final FirebaseAuth _auth =
      FirebaseAuth.instance;


  final GoogleSignIn _googleSignIn =
      GoogleSignIn();


  final FirestoreService _db =
      FirestoreService.instance;



  // ============================================================
  // SESSÕES SALVAS
  // ============================================================


  static const String _kStudentRoomIdKey =
      'session_student_roomId';


  static const String _kStudentIdKey =
      'session_student_id';



  static const String _kProfessorRoomKey =
      'session_professor_roomId';





  // ============================================================
  // ESTADO ATUAL
  // ============================================================


  UserModel? _currentUser;


  StudentModel? _currentStudent;


  RoomModel? _currentRoom;



  bool _isLoading = false;


  bool _isRestoringSession = true;


  String? _errorMessage;





  // ============================================================
  // DADOS TEMPORÁRIOS DO LOGIN DO ALUNO
  // ============================================================


  String? _pendingRoomId;


  String? _pendingProfessorId;


  String? _pendingProfessorName;


  String? _pendingRoomCode;



  List<StudentModel> _pendingRoomStudents = [];





  // ============================================================
  // GETTERS
  // ============================================================


  UserModel? get currentUser =>
      _currentUser;



  StudentModel? get currentStudent =>
      _currentStudent;



  RoomModel? get currentRoom =>
      _currentRoom;




  bool get isLoading =>
      _isLoading;



  bool get isRestoringSession =>
      _isRestoringSession;



  String? get errorMessage =>
      _errorMessage;



  bool get isAuthenticated =>
      _currentUser != null ||
      _currentStudent != null;



  bool get isProfessor =>
      _currentUser?.role ==
      UserRole.professor;



  String? get pendingRoomId =>
      _pendingRoomId;



  String? get pendingProfessorId =>
      _pendingProfessorId;



  String? get pendingProfessorName =>
      _pendingProfessorName;



  String? get pendingRoomCode =>
      _pendingRoomCode;



  List<StudentModel> get pendingRoomStudents =>
      _pendingRoomStudents;
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
 // ============================================================
// RESTAURAR SESSÃO
// ============================================================

Future<void> tryAutoLogin() async {

  _isRestoringSession = true;

  notifyListeners();


  try {


    final fbUser =
        _auth.currentUser;



    // =========================================================
    // PROFESSOR
    // =========================================================


    if(
      fbUser != null &&
      !fbUser.isAnonymous
    ){


      _currentUser = UserModel(

        id: fbUser.uid,

        name:
            fbUser.displayName ??
            _nameFromEmail(
              fbUser.email ?? '',
            ),

        email:
            fbUser.email ?? '',

        role:
            UserRole.professor,

      );



      // Recupera última sala selecionada

      final prefs =
          await SharedPreferences.getInstance();


      final savedRoomId =
          prefs.getString(
            _kProfessorRoomKey,
          );



      if(savedRoomId != null){


        try {


          final room =
              await _db.roomDocById(
                savedRoomId,
              )
              .get();



          if(room.exists){


            _currentRoom =
                RoomModel.fromFirestore(
                  room,
                );


          }


        }catch(e){


          debugPrint(
            'Erro ao restaurar sala professor: $e',
          );


        }


      }



      _isRestoringSession = false;

      notifyListeners();

      return;

    }







    // =========================================================
    // ALUNO
    // =========================================================


    final prefs =
        await SharedPreferences.getInstance();



    final savedRoomId =
        prefs.getString(
          _kStudentRoomIdKey,
        );


  

final savedStudentId =
    prefs.getString(
      _kStudentIdKey,
    );





   if(
  savedRoomId != null &&
  savedStudentId != null
){



      if(
        _auth.currentUser == null
      ){

        await _auth.signInAnonymously();

      }




      final students =
    await _db.fetchStudents(
      roomId: savedRoomId,
    );


      StudentModel? match;



      for(final student in students){


        if(
          student.id ==
          savedStudentId
        ){

          match = student;

          break;

        }


      }



      if(match != null){


        _currentStudent =
            match;



        final room =
            await _db.roomDocById(
              savedRoomId,
            )
            .get();



        if(room.exists){


          _currentRoom =
              RoomModel.fromFirestore(
                room,
              );


        }



      }else{


        await prefs.remove(
          _kStudentRoomIdKey,
        );


       


        await prefs.remove(
          _kStudentIdKey,
        );


      }



    }



  }catch(e){


    debugPrint(
      'Erro ao restaurar sessão: $e',
    );


  }



  _isRestoringSession = false;


  notifyListeners();


}
  // ── Login com e-mail e senha ─────────────────────────────────────────────
// ============================================================
// LOGIN PROFESSOR
// ============================================================

Future<bool> loginProfessor(
  String email,
  String password,
) async {

  _isLoading = true;
  _errorMessage = null;
  notifyListeners();


  try {


    final credential =
        await _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );


    final user =
        credential.user;


    if(user == null){
      throw FirebaseAuthException(
        code: 'null-user',
      );
    }



    _currentUser = UserModel(

      id: user.uid,

      name:
          user.displayName ??
          _nameFromEmail(
            user.email ?? '',
          ),

      email:
          user.email ?? '',

      role:
          UserRole.professor,

    );



    _isLoading = false;

    notifyListeners();


    return true;



  }on FirebaseAuthException catch(e){


    _errorMessage =
        _translateError(
          e.code,
        );


    _isLoading = false;

    notifyListeners();


    return false;


  }catch(e){


    debugPrint(
      'Erro login professor: $e',
    );


    _errorMessage =
        'Erro ao realizar login.';


    _isLoading = false;

    notifyListeners();


    return false;

  }

}



// ============================================================
// CADASTRO PROFESSOR
// ============================================================


Future<bool> registerProfessor(
  String name,
  String email,
  String password,
) async {


  _isLoading = true;

  _errorMessage = null;

  notifyListeners();



  try {


    final credential =
        await _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );



    final user =
        credential.user;



    if(user == null){

      throw FirebaseAuthException(
        code:'null-user',
      );

    }



    await user.updateDisplayName(
      name.trim(),
    );



    _currentUser =
        UserModel(

          id:user.uid,

          name:name.trim(),

          email:
              user.email ?? '',

          role:
              UserRole.professor,

        );



    _isLoading=false;

    notifyListeners();



    return true;



  }on FirebaseAuthException catch(e){


    _errorMessage =
        _translateError(
          e.code,
        );


    _isLoading=false;

    notifyListeners();


    return false;



  }catch(e){


    debugPrint(
      'Erro cadastro professor: $e',
    );


    _errorMessage =
        'Erro inesperado.';



    _isLoading=false;

    notifyListeners();


    return false;

  }

}
  // ── Cadastro com e-mail e senha ──────────────────────────────────────────
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
        // A criação/recuperação da sala é feita à parte: se ela falhar
        // (ex.: índice do Firestore, rede), o login com Google já foi
        // concluído com sucesso e não deve ser desfeito por causa disso.
        // ProfessorController.loadData() tenta de novo ao entrar no dashboard.
        try {
          await _db.getOrCreateRoom(professorId: user.uid, professorName: _currentUser!.name);
        } catch (e) {
          debugPrint('Aviso: falha ao preparar sala após login Google (web): $e');
        }
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
      // Mesma lógica do fluxo web: não deixar uma falha ao criar/recuperar
      // a sala derrubar um login Google que já foi concluído com sucesso.
      try {
        await _db.getOrCreateRoom(professorId: user.uid, professorName: _currentUser!.name);
      } catch (e) {
        debugPrint('Aviso: falha ao preparar sala após login Google (mobile): $e');
      }

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

  // ============================================================
// LOGIN ALUNO PELO CÓDIGO DA SALA
// ============================================================


Future<bool> loginWithRoomCode(
  String roomCode,
) async {


  _isLoading = true;

  _errorMessage = null;

  notifyListeners();



  final code =
      roomCode.trim().toUpperCase();



  if(code.length != 6){


    _errorMessage =
        'Código de sala inválido.';


    _isLoading=false;

    notifyListeners();


    return false;

  }



  try {



    // Login anônimo para leitura do Firestore

    if(_auth.currentUser == null){


      await _auth.signInAnonymously();


    }



    final room =
        await _db.resolveRoomByCode(
          code,
        );



    if(room == null){


      _errorMessage =
          'Sala não encontrada.';


      _isLoading=false;

      notifyListeners();


      return false;


    }



    final roomId =
        room['roomId']!;



    final professorId =
        room['professorId']!;




    // Busca alunos DENTRO DA SALA correta

    final students =
        await _db.fetchStudents(
          roomId: roomId,
        );



    if(students.isEmpty){


      _errorMessage =
          'Essa sala ainda não possui alunos cadastrados.';



      _isLoading=false;

      notifyListeners();


      return false;


    }




    _pendingRoomId =
        roomId;



    _pendingProfessorId =
        professorId;



    _pendingProfessorName =
        room['professorName'];



    _pendingRoomCode =
        room['code'];



    _pendingRoomStudents =
        students;



    _isLoading=false;

    notifyListeners();



    return true;




  }on FirebaseAuthException catch(e){



    debugPrint(
      'Erro Firebase login sala: ${e.code}',
    );


    _errorMessage =
        'Erro ao acessar sala.';



    _isLoading=false;

    notifyListeners();


    return false;



  }catch(e){



    debugPrint(
      'Erro login sala: $e',
    );



    _errorMessage =
        'Erro ao entrar na sala.';



    _isLoading=false;

    notifyListeners();



    return false;


  }


}
// ============================================================
// REGISTRAR PERFIL DO ALUNO NA SALA
// ============================================================


Future<bool> registerStudentProfile({

  required String name,

  required String avatarIndex,

}) async {



  if(
    _pendingRoomId == null ||
    _pendingProfessorId == null
  ){

    return false;

  }



  _isLoading = true;

  _errorMessage = null;

  notifyListeners();




  final typedName =
      name.trim().toLowerCase();




  StudentModel? match;



  for(final student in _pendingRoomStudents){


    if(
      student.name
          .trim()
          .toLowerCase() ==
      typedName
    ){

      match = student;

      break;

    }


  }




  if(match == null){


    _errorMessage =
        'Aluno não encontrado nesta sala.';



    _isLoading=false;

    notifyListeners();


    return false;


  }





  try {



    await _db.updateStudentAvatar(

      roomId:
          _pendingRoomId!,

      studentId:
          match.id,

      avatarIndex:
          avatarIndex,

    );





    _currentStudent =
        match.copyWith(

          avatarIndex:
              avatarIndex,

        );





    // Recupera sala atual

    final room =
        await _db.roomDocById(
          _pendingRoomId!,
        )
        .get();




    if(room.exists){


      _currentRoom =
          RoomModel.fromFirestore(
            room,
          );


    }






    // Salva sessão do aluno


    final prefs =
        await SharedPreferences
            .getInstance();




    await prefs.setString(

      _kStudentRoomIdKey,

      _pendingRoomId!,

    );



   await prefs.setString(

  _kStudentRoomIdKey,

  _pendingRoomId!,

);


await prefs.setString(

  _kStudentIdKey,

  match.id,

);






    _isLoading=false;


    notifyListeners();



    return true;




  }catch(e){


    debugPrint(
      'Erro registro aluno: $e',
    );


    _errorMessage =
        'Erro ao entrar na turma.';



    _isLoading=false;


    notifyListeners();



    return false;


  }


}
// ============================================================
// LOGOUT
// ============================================================


Future<void> logout() async {


  await _auth.signOut();


  await _googleSignIn.signOut();




  final prefs =
      await SharedPreferences
          .getInstance();




await prefs.remove(
  _kStudentRoomIdKey,
);


await prefs.remove(
  _kStudentIdKey,
);


  await prefs.remove(
    _kProfessorRoomKey,
  );





  _currentUser = null;


  _currentStudent = null;


  _currentRoom = null;



  _pendingRoomId = null;


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
