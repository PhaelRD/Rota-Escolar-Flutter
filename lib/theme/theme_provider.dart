import 'package:flutter/material.dart';
import 'app_theme.dart';

class ThemeProvider with ChangeNotifier {
  // Estado inicial: tema claro
  ThemeData _currentTheme = AppTheme.lightTheme;

  // Getter para acessar o tema atual
  ThemeData get currentTheme => _currentTheme;

  // Getter para verificar se o tema atual é escuro
  bool get isDarkMode => _currentTheme == AppTheme.darkTheme;

  // Função para alternar entre tema claro e escuro
  void toggleTheme() {
    // Alterna entre tema claro e escuro
    if (_currentTheme == AppTheme.lightTheme) {
      _currentTheme = AppTheme.darkTheme;
    } else {
      _currentTheme = AppTheme.lightTheme;
    }
    notifyListeners(); // Notifica os widgets para atualizarem
  }
}
