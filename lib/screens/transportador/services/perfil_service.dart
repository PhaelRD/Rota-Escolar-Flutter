// perfil_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class PerfilService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  Future<Map<String, dynamic>?> loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final snapshot =
          await _dbRef.child('users').child(user.uid).child('userInfos').get();
      if (snapshot.exists && snapshot.value != null) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
    }
    return null;
  }

  Future<void> updateUserData(String field, String newValue) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _dbRef.child('users').child(user.uid).child('userInfos').update({
        field: newValue,
      });
    }
  }

  Future<void> updateProfilePicture(int newIndex) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _dbRef.child('users').child(user.uid).child('userInfos').update({
        'profilePicture': newIndex,
      });
    }
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;

    if (user != null) {
      try {
        // Remove os dados do usuário no Realtime Database
        await _dbRef.child('users').child(user.uid).remove();

        // Exclui a conta do Firebase Authentication
        await user.delete();
      } catch (e) {
        print("Erro ao excluir conta: $e");
        rethrow;
      }
    }
  }
}
