import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/screens/login_screen.dart';
import 'widgets/transportador_drawer.dart';
import 'package:provider/provider.dart';
import 'package:myapp/theme/theme_provider.dart';
import 'package:myapp/screens/transportador/services/assinatura_service.dart';
import 'package:url_launcher/url_launcher.dart';

class AssinaturaScreen extends StatefulWidget {
  const AssinaturaScreen({super.key});

  @override
  _AssinaturaScreenState createState() => _AssinaturaScreenState();
}

class _AssinaturaScreenState extends State<AssinaturaScreen> {
  String? plano;

  @override
  void initState() {
    super.initState();
    _fetchPlano();
  }

  Future<void> _fetchPlano() async {
    final AssinaturaService assinaturaService = AssinaturaService();
    try {
      String? userPlano = await assinaturaService.getPlano();
      setState(() {
        plano = userPlano;
      });
    } catch (e) {
      print("Erro ao buscar plano: $e");
    }
  }

  Future<void> _assinar() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        final AssinaturaService assinaturaService = AssinaturaService();
        String? email = await assinaturaService.getEmail();
        if (email != null) {
          final String url =
              "https://buy.stripe.com/8wM6q268abRm4jm146?prefilled_email=${Uri.encodeComponent(email)}&client_reference_id=${currentUser.uid}";

          if (await canLaunch(url)) {
            await launch(url);
          } else {
            print("Não foi possível abrir a URL");
          }
        } else {
          print("Email não encontrado");
        }
      } catch (e) {
        print("Erro ao buscar email: $e");
      }
    }
  }

  Widget _buildBenefitItem(String benefit, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent),
          const SizedBox(width: 8),
          Expanded(child: Text(benefit, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  Widget _buildSubscriptionDetails() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "R\$ 60,00/mês",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Plano Profissional",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildBenefitItem("50 registros de escolas", Icons.school),
            _buildBenefitItem("150 registros de alunos", Icons.people),
            _buildBenefitItem("Enviar convites", Icons.send),
            _buildBenefitItem("Envio de emails de avisos", Icons.email),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      Future.microtask(() {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      });
      return const SizedBox();
    }

    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = themeProvider.currentTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assinatura'),
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
      drawer: const TransportadorMenuDrawer(),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 30),
              _buildSubscriptionDetails(),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () async {
                  await _assinar();
                },
                child: Text(plano == '0' ? 'Assinar' : 'Gerenciar Assinatura'),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
