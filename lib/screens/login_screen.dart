import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:myapp/screens/register_screen.dart';
import 'package:myapp/screens/reset_password_screen.dart';
import 'package:myapp/screens/transportador/home_screen.dart';
import 'package:myapp/screens/aluno/home_screen.dart';
import 'package:myapp/screens/pai/home_screen.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:myapp/theme/theme_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _rememberMe = false;
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  int _loginAttempts = 0;
  final int _maxLoginAttempts = 3;
  DateTime? _lockoutTime;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    _rememberMe = prefs.getBool('remember_me') ?? false;
    if (_rememberMe) {
      _emailController.text = prefs.getString('saved_email') ?? '';
      // Carrega a senha se "Lembre de mim" estiver ativo
      final savedPassword = prefs.getString('saved_password');
      if (savedPassword != null) {
        _passwordController.text = savedPassword;
      }
    }
  });

  // Verifica se a sessão de login está expirada (mais de 12 horas)
  final authService = AuthService();
  bool isExpired = await authService.isLoginExpired();
  if (isExpired) {
    // Se a sessão estiver expirada, limpe as credenciais salvas
    await prefs.remove('saved_email');
    await prefs.remove('saved_password');
    await prefs.setBool('remember_me', false);
    return; // Não tenta o login automático
  }

  // Se "Lembre de mim" estiver ativo e a sessão não estiver expirada,
  // tenta realizar o login automático
  if (_rememberMe) {
    await _login(savedPassword: _passwordController.text);
  }
}



  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setBool('remember_me', true);
      await prefs.setString('saved_email', _emailController.text);
      await prefs.setString('saved_password', _passwordController.text);
    } else {
      await prefs.remove('remember_me');
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
    }
  }

  Future<void> _login({String? savedPassword}) async {
    if (_lockoutTime != null && DateTime.now().isBefore(_lockoutTime!)) {
      _showErrorDialog(
          'Muitas tentativas de login. Tente novamente em alguns minutos.');
      return;
    }

    if (_formKey.currentState!.validate() || savedPassword != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authService = AuthService();
        final password = savedPassword ?? _passwordController.text;
        final userType = await authService.loginUser(
          email: _emailController.text.trim(),
          password: password,
          rememberMe: _rememberMe,
        );

        _loginAttempts = 0;
        _lockoutTime = null;

        await _saveCredentials();

        _navigateToHomeScreen(userType);
      } catch (e) {
        _loginAttempts++;

        if (_loginAttempts >= _maxLoginAttempts) {
          _lockoutTime = DateTime.now().add(const Duration(minutes: 5));
        }

        _showErrorDialog(_getErrorMessage(e));
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getErrorMessage(Object error) {
    if (error.toString().contains('invalid-credentials')) {
      return 'E-mail ou senha incorretos. Verifique suas credenciais.';
    } else if (error.toString().contains('network-error')) {
      return 'Erro de conexão. Verifique sua internet.';
    }
    return 'Erro ao fazer login. Tente novamente.';
  }

  void _navigateToHomeScreen(String userType) {
    final homeScreens = {
      '0': const TransportadorHomeScreen(),
      '1': const AlunoHomeScreen(),
      '2': const PaiHomeScreen(),
    };

    final homeScreen = homeScreens[userType];
    if (homeScreen != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => homeScreen),
      );
    } else {
      _showErrorDialog("Tipo de usuário desconhecido.");
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Erro de Login"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Fechar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = themeProvider.currentTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: currentTheme.colorScheme.primary,
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            ),
            onPressed: themeProvider.toggleTheme,
            tooltip: 'Alternar tema',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'E-mail',
                  prefixIcon: const Icon(Icons.email),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  filled: true,
                  fillColor: currentTheme.colorScheme.surface,
                ),
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
                textInputAction: TextInputAction.next,
                autocorrect: false,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  filled: true,
                  fillColor: currentTheme.colorScheme.surface,
                ),
                validator: _validatePassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _login(),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value!;
                          });
                        },
                      ),
                      const Text('Lembre de mim'),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ResetPasswordScreen()),
                      );
                    },
                    child: const Text(
                      'Esqueceu a senha?',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  backgroundColor: currentTheme.colorScheme.secondary,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : const Text('Entrar', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const RegisterScreen()),
                  );
                },
                child: Text(
                  'Não tem uma conta? Cadastre-se',
                  style: TextStyle(
                    color: currentTheme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, insira seu e-mail.';
    }
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zAZ0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Por favor, insira um e-mail válido.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, insira sua senha.';
    }
    if (value.length < 8) {
      return 'A senha deve ter pelo menos 8 caracteres.';
    }
    return null;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
