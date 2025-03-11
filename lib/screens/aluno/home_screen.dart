import 'package:flutter/material.dart';

class AlunoHomeScreen extends StatelessWidget {
  const AlunoHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tela para Aluno')),
      body: const Center(child: Text('Bem-vindo, Aluno!')),
    );
  }
}
