import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: Colors.black, // Cor principal (Preto)
      secondary: Color.fromARGB(255, 255, 235, 59), // Cor de destaque (Amarelo)
      surface: Colors.white, // Fundo geral (cinza claro)
      error: Colors.red, // Cor de erro
      onPrimary: Colors.white, // Cor do texto e ícones sobre primários
      onSecondary: Colors.black, // Cor do texto e ícones sobre secundários
      onSurface: Colors.black, // Cor do texto sobre superfícies
      onError: Colors.white, // Cor do texto sobre erros
    ),
    cardTheme: const CardTheme(
      color: Colors.white,
      shadowColor: Colors.grey,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(15)),
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black), // Texto principal
      bodyMedium: TextStyle(color: Colors.grey), // Texto secundário
      labelLarge: TextStyle(color: Colors.black), // Rótulos
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black, // Fundo do AppBar
      foregroundColor: Colors.white, // Texto e ícones do AppBar
      elevation: 4, // Elevação padrão
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.yellow, // Fundo do botão
        foregroundColor: Colors.black, // Texto no botão
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      labelStyle: TextStyle(color: Colors.grey), // Texto do rótulo
      filled: true,
      fillColor: Colors.white, // Fundo do campo de entrada
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.black), // Borda habilitada
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.yellow), // Borda focada
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.all(Colors.yellow),
      checkColor: WidgetStateProperty.all(Colors.black),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: Colors.white, // Cor principal (Branco)
      secondary: Colors.yellow, // Cor de destaque (Amarelo)
      surface: Color(0xFF1E1E1E), // Fundo geral (preto)
      error: Colors.red, // Cor de erro
      onPrimary: Colors.black, // Cor do texto e ícones sobre primários
      onSecondary: Colors.black, // Cor do texto e ícones sobre secundários
      onSurface: Colors.white, // Cor do texto sobre superfícies
      onError: Colors.black, // Cor do texto sobre erros
    ),
    cardTheme: const CardTheme(
      color: Color(0xFF1E1E1E),
      shadowColor: Colors.black,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(15)),
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white), // Texto principal
      bodyMedium: TextStyle(color: Colors.grey), // Texto secundário
      labelLarge: TextStyle(color: Colors.white), // Rótulos
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black, // Fundo do AppBar
      foregroundColor: Colors.black, // Texto e ícones do AppBar
      elevation: 4, // Elevação padrão
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.yellow, // Fundo do botão
        foregroundColor: Colors.black, // Texto no botão
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      labelStyle: TextStyle(color: Colors.grey), // Texto do rótulo
      filled: true,
      fillColor: Color(0xFF1E1E1E), // Fundo do campo de entrada
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.white), // Borda habilitada
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.yellow), // Borda focada
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.all(Colors.yellow),
      checkColor: WidgetStateProperty.all(Colors.black),
    ),
  );
}
