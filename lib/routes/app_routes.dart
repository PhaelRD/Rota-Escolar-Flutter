import 'package:flutter/material.dart';
import 'package:myapp/screens/transportador/perfil_screen.dart';
import 'package:myapp/screens/transportador/home_screen.dart';
import 'package:myapp/screens/transportador/assinatura_screen.dart';
import 'package:myapp/screens/transportador/escolas_screen.dart';
import 'package:myapp/screens/transportador/alunos_screen.dart';
import 'package:myapp/screens/transportador/reajuste_screen.dart';
import 'package:myapp/screens/transportador/gastos_screen.dart'; // Importa a tela de gastos
import 'package:myapp/screens/transportador/avisos_screen.dart'; // Importa a tela de avisos

class AppRoutes {
  static const String perfil_transportador = '/perfil_transportador';
  static const String dashboard_transportador = '/dashboard_transportador';
  static const String escolas_transportador = '/escolas_transportador';
  static const String alunos_transportado = '/alunos_transportado';
  static const String reajuste_transportador = '/reajuste_transportador';
  static const String gastos_transportador = '/gastos_transportador'; // Rota de gastos adicionada
  static const String avisos_transportador = '/avisos_transportador'; // Rota de avisos adicionada
  static const String rastrear = '/rastrear';
  static const String assinar_transportador = '/assinar_transportador';
  static const String editar_pagamento = '/editar_pagamento';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case perfil_transportador:
        return MaterialPageRoute(builder: (_) => const PerfilUsuarioScreen());
      case dashboard_transportador:
        return MaterialPageRoute(builder: (_) => const TransportadorHomeScreen());
      case escolas_transportador:
        return MaterialPageRoute(builder: (_) => const EscolasScreen());
      case alunos_transportado:
        return MaterialPageRoute(builder: (_) => const AlunosScreen());
      case assinar_transportador:
        return MaterialPageRoute(builder: (_) => const AssinaturaScreen());
      case reajuste_transportador:
        return MaterialPageRoute(builder: (_) => const ReajusteScreen());
      case gastos_transportador:
        return MaterialPageRoute(builder: (_) => const GastosScreen());
      case avisos_transportador:
        return MaterialPageRoute(builder: (_) => const AvisosScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Tela não encontrada')),
          ),
        );
    }
  }
}
