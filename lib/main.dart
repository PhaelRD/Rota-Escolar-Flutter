import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/screens/login_screen.dart';
import 'package:myapp/screens/transportador/home_screen.dart';
import 'package:myapp/screens/aluno/home_screen.dart';
import 'package:myapp/screens/pai/home_screen.dart';
import 'package:myapp/theme/theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Para gerenciar autenticação
import 'package:firebase_database/firebase_database.dart'; // Para acessar o Realtime Database
import 'firebase_options.dart'; // Configuração do Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:myapp/routes/app_routes.dart'; // Inicialização do Firebase

void main() async {
  // Inicializa o Firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Verifica se o usuário está logado
  User? currentUser = FirebaseAuth.instance.currentUser;

  if (currentUser != null) {
    // O usuário está logado, vamos buscar o tipo de usuário (userType) no Realtime Database
    _getUserTypeAndRedirect(currentUser.uid);
  } else {
    // O usuário não está logado, inicia o fluxo de login
    runApp(const MyApp(isLoggedIn: false));
  }
}

Future<void> _getUserTypeAndRedirect(String userId) async {
  DatabaseReference userRef = FirebaseDatabase.instance.ref('users/$userId');
  DataSnapshot snapshot = await userRef.get();

  if (snapshot.exists) {
    String userType = snapshot.child('userType').value.toString();
    runApp(MyApp(isLoggedIn: true, userType: userType));
  } else {
    // Se não encontrar o usuário no DB, redireciona para o login
    runApp(const MyApp(isLoggedIn: false));
  }
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final String userType;

  const MyApp({super.key, required this.isLoggedIn, this.userType = ''});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()), // Fornecendo o ThemeProvider
      ],
      child: Builder(
        builder: (context) {
          // Obtém o tema atual a partir do ThemeProvider
          final themeProvider = Provider.of<ThemeProvider>(context);
          return MaterialApp(
            title: 'Sistema de Transporte Escolar', // Título do app
            theme: themeProvider.currentTheme, // Define o tema atual
            darkTheme: themeProvider.currentTheme, // Tema escuro, se implementado no ThemeProvider
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: isLoggedIn
                ? HomeScreen(userType: userType)
                : const LoginScreen(),
            debugShowCheckedModeBanner: false, // Remove o banner de depuração
            onGenerateRoute: AppRoutes.generateRoute, // Link to the route generator
          );
        },
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final String userType;

  const HomeScreen({super.key, required this.userType});

  @override
  Widget build(BuildContext context) {
    // Aqui, após obter o tipo de usuário, redireciona para a tela correta
    switch (userType) {
      case '0': // Transportador
        return const TransportadorHomeScreen();
      case '1': // Aluno
        return const AlunoHomeScreen();
      case '2': // Pai
        return const PaiHomeScreen();
      default:
        return const LoginScreen(); // Caso não tenha o userType, redireciona para o login
    }
  }
}
