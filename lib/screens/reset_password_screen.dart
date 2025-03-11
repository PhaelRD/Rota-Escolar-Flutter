import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/theme/theme_provider.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isProcessing = false;

  // Função para enviar o link de redefinição de senha
  Future<void> _sendPasswordResetLink() async {
    if (_emailController.text.isEmpty) {
      _showErrorDialog('Por favor, insira seu e-mail.');
      return;
    }

    if (!_isEmailValid(_emailController.text)) {
      _showErrorDialog('E-mail inválido.');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text,
      );
      _showSuccessDialog('Link de redefinição de senha enviado para o seu e-mail.');
    } on FirebaseAuthException catch (e) {
      _showErrorDialog('Erro: ${e.message}');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // Função para validar e-mail
  bool _isEmailValid(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // Função para exibir diálogo de erro
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erro'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  // Função para exibir diálogo de sucesso
  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sucesso'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Fecha o diálogo de sucesso
              Navigator.pop(context); // Volta para a tela de login
            },
            child: const Text('Fechar'),
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
        title: const Text('Redefinir Senha'),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Insira seu e-mail para redefinir a senha',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _emailController,
                label: 'E-mail',
                keyboardType: TextInputType.emailAddress,
                theme: currentTheme,
                icon: Icons.email, // Ícone para o campo de e-mail
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Por favor, insira seu e-mail.';
                  } else if (!_isEmailValid(value)) {
                    return 'E-mail inválido.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isProcessing ? null : _sendPasswordResetLink,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  backgroundColor: currentTheme.colorScheme.secondary,
                ),
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Enviar Link de Redefinição',
                        style: TextStyle(fontSize: 18),
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
    required ThemeData theme,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        filled: true,
        fillColor: theme.colorScheme.surface,
        prefixIcon: Icon(icon, color: theme.colorScheme.primary),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }
}
