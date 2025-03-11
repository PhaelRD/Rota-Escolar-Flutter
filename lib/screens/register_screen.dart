import 'package:flutter/material.dart';
import 'package:myapp/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:myapp/screens/login_screen.dart';
import 'package:myapp/screens/transportador/home_screen.dart';
import 'package:myapp/theme/theme_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _usernameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Sempre será criado como Transportador
  final String _userType = '0';
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        _showErrorDialog("As senhas não coincidem.");
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        AuthService authService = AuthService();

        // Registrar o usuário em Firebase Authentication
        final userId = await authService.registerUser(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          whatsapp: _whatsappController.text.trim(),
          userType: _userType,
          username: _usernameController.text.trim(),
        );

        // Navegar para a tela inicial do Transportador
        _navigateToHomeScreen();
      } catch (e) {
        _showErrorDialog("Erro ao registrar: $e");
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToHomeScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const TransportadorHomeScreen()),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Erro"),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
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
        title: const Text('Cadastro'),
        backgroundColor: currentTheme.colorScheme.primary,
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            ),
            onPressed: themeProvider.toggleTheme,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              _buildTextField(
                controller: _usernameController,
                label: 'Nome de usuário',
                validator:
                    (value) =>
                        value!.isEmpty
                            ? 'Por favor, insira um nome de usuário.'
                            : null,
                theme: currentTheme,
                icon: Icons.person,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _emailController,
                label: 'E-mail',
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Por favor, insira seu e-mail.';
                  } else if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(value)) {
                    return 'Por favor, insira um e-mail válido.';
                  }
                  return null;
                },
                theme: currentTheme,
                icon: Icons.email,
              ),
              const SizedBox(height: 16),
              _buildPasswordField(
                controller: _passwordController,
                label: 'Senha',
                isPasswordVisible: _isPasswordVisible,
                togglePasswordVisibility: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
                theme: currentTheme,
                icon: Icons.lock,
              ),
              const SizedBox(height: 16),
              _buildPasswordField(
                controller: _confirmPasswordController,
                label: 'Confirmar Senha',
                isPasswordVisible: _isConfirmPasswordVisible,
                togglePasswordVisibility: () {
                  setState(() {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  });
                },
                theme: currentTheme,
                icon: Icons.lock,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _whatsappController,
                label: 'Número do WhatsApp',
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Por favor, insira o número do WhatsApp.';
                  } else if (!RegExp(r'^\+?1?\d{9,15}$').hasMatch(value)) {
                    return 'Por favor, insira um número válido.';
                  }
                  return null;
                },
                theme: currentTheme,
                icon: Icons.phone,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  backgroundColor: currentTheme.colorScheme.secondary,
                ),
                child:
                    _isLoading
                        ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        )
                        : const Text(
                          'Cadastrar',
                          style: TextStyle(fontSize: 18),
                        ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                child: Text(
                  'Já tem uma conta? Faça login',
                  style: TextStyle(color: currentTheme.colorScheme.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    required ThemeData theme,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: theme.colorScheme.surface,
        prefixIcon: Icon(icon, color: theme.colorScheme.primary),
      ),
      validator: validator,
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required ThemeData theme,
    required bool isPasswordVisible,
    required VoidCallback togglePasswordVisibility,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !isPasswordVisible,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: theme.colorScheme.surface,
        prefixIcon: Icon(icon, color: theme.colorScheme.primary),
        suffixIcon: IconButton(
          icon: Icon(
            isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: theme.colorScheme.primary,
          ),
          onPressed: togglePasswordVisibility,
        ),
      ),
      validator: (value) {
        if (value!.isEmpty) {
          return 'Por favor, insira sua senha.';
        } else if (value.length < 6) {
          return 'A senha deve ter pelo menos 6 caracteres.';
        }
        return null;
      },
    );
  }
}
