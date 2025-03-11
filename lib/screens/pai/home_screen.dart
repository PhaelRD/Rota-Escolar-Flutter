import 'package:flutter/material.dart';

class PaiHomeScreen extends StatelessWidget {
  const PaiHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tela para Pais')),
      body: const Center(child: Text('Bem-vindo, Pai!')),
    );
  }
}
