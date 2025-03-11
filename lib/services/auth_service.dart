import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myapp/screens/login_screen.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  /// **Registrar Usuário no Firebase**
  Future<String> registerUser({
    required String email,
    required String password,
    required String username,
    required String whatsapp,
    required String userType,
  }) async {
    try {
      // Criar o usuário no Firebase Authentication
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        String uid = userCredential.user!.uid;

        // Salvar os dados iniciais do usuário no Realtime Database
        await _dbRef.child('users').child(uid).child('userInfos').set({
          'username': username,
          'email': email,
          'whatsapp': whatsapp,
          'userType': userType,
          'profilePicture': '0',
          'plano': '0',
        });

        return uid;
      } else {
        throw 'Erro ao registrar o usuário.';
      }
    } catch (e) {
      throw 'Erro ao registrar o usuário: $e';
    }
  }

  /// **Login do Usuário**
  Future<String> loginUser({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        String uid = userCredential.user!.uid;

        // Armazena o timestamp do login
        await _storeLoginTimestamp();

        // Busca as informações do usuário no Realtime Database
        DataSnapshot snapshot =
            await _dbRef.child('users').child(uid).child('userInfos').get();

        if (snapshot.exists) {
          return snapshot.child('userType').value.toString();
        } else {
          throw 'Usuário não encontrado no banco de dados.';
        }
      } else {
        throw 'Falha no login';
      }
    } catch (e) {
      throw 'Erro ao fazer login: $e';
    }
  }

  /// **Armazena o timestamp do login (em milissegundos)**
  Future<void> _storeLoginTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("loginTimestamp", DateTime.now().millisecondsSinceEpoch);
  }

  /// **Verifica se o login expirou (após 10 horas)**
  Future<bool> isLoginExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt("loginTimestamp");
    if (timestamp == null) {
      return true; // Se não houver registro, considere expirado
    }
    final loginTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateTime.now().difference(loginTime) > const Duration(hours: 10);
  }

  /// **Verificar se a sessão do usuário expirou**
  Future<void> checkLoginExpiration(BuildContext context) async {
    if (await isLoginExpired()) {
      await logoutUser(context);
    }
  }

  /// **Logout do Usuário**
  Future<void> logoutUser(BuildContext context) async {
    try {
      await _auth.signOut();
      // Opcional: Limpa o timestamp de login
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove("loginTimestamp");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      throw 'Erro ao fazer logout: $e';
    }
  }

  /// **Obter Usuário Atual**
  Future<User?> getCurrentUser() async {
    User? user = _auth.currentUser;
    return user;
  }

  /// **Alterar Senha do Usuário**
  Future<void> changePassword({required String newPassword}) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
      } else {
        throw 'Usuário não autenticado';
      }
    } catch (e) {
      throw 'Erro ao alterar a senha: $e';
    }
  }
}
