import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AssinaturaService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// **Busca o plano do usuário**
  Future<String?> getPlano() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw 'Usuário não autenticado';
      }
      DataSnapshot snapshot =
          await _dbRef
              .child('users')
              .child(user.uid)
              .child('userInfos')
              .child('plano')
              .get();
      if (snapshot.exists) {
        return snapshot.value.toString();
      } else {
        return null;
      }
    } catch (e) {
      throw 'Erro ao buscar plano: $e';
    }
  }

  /// **Busca o UserID do usuário autenticado**
  Future<String?> getUserId() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        return user.uid;
      } else {
        return null;
      }
    } catch (e) {
      throw 'Erro ao buscar UserID: $e';
    }
  }

  /// **Busca o email do usuário autenticado**
  Future<String?> getEmail() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw 'Usuário não autenticado';
      }
      DataSnapshot snapshot =
          await _dbRef
              .child('users')
              .child(user.uid)
              .child('userInfos')
              .child('email')
              .get();
      if (snapshot.exists) {
        return snapshot.value.toString();
      } else {
        return null;
      }
    } catch (e) {
      throw 'Erro ao buscar email: $e';
    }
  }
}
