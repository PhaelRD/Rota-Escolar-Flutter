import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:myapp/services/auth_service.dart'; // Certifique-se de que o caminho do arquivo esteja correto

class TransportadorMenuDrawer extends StatefulWidget {
  const TransportadorMenuDrawer({super.key});

  @override
  _TransportadorMenuDrawerState createState() =>
      _TransportadorMenuDrawerState();
}

class _TransportadorMenuDrawerState extends State<TransportadorMenuDrawer> {
  String profileImage = 'lib/img/profile/0.png'; // Imagem padrão local
  String username = 'Carregando...'; // Valor inicial até a consulta ser feita
  final _auth = FirebaseAuth.instance;
  final _dbRef = FirebaseDatabase.instance.ref();
  bool _isAlunosExpanded = false; // Controla o estado do botão expansível

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Carregar dados do usuário a partir do nó userInfos
        final snapshot =
            await _dbRef
                .child('users')
                .child(user.uid)
                .child('userInfos')
                .get();
        if (snapshot.exists && snapshot.value != null) {
          final data = Map<String, dynamic>.from(snapshot.value as Map);

          // Atualizar imagem de perfil
          final profilePictureIndex =
              data['profilePicture']; // Valor numérico da imagem
          setState(() {
            // Gerar caminho da imagem de perfil com base no índice
            profileImage = 'lib/img/profile/$profilePictureIndex.png';

            // Carregar nome do usuário
            username = data['username'] ?? 'Nome não encontrado';
          });
        }
      }
    } catch (e) {
      // Caso ocorra erro na consulta, manter imagem padrão
      setState(() {
        profileImage =
            'lib/img/profile/0.png'; // Imagem padrão (caso não haja erro)
        username = 'Erro ao carregar nome';
      });
    }
  }

  // Função de logout
  Future<void> _logout() async {
    try {
      // Chama a função de logout do AuthService
      await AuthService().logoutUser(context);
    } catch (e) {
      // Trate qualquer erro de logout
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao fazer logout: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Acessando o tema atual
    final theme = Theme.of(context);

    // Definir as cores do nome e do tipo de conta com base no tema atual
    final accountNameTextStyle = TextStyle(
      color: theme.brightness == Brightness.dark ? Colors.black : Colors.white,
    );
    final accountEmailTextStyle = TextStyle(
      color: theme.brightness == Brightness.dark ? Colors.black : Colors.white,
    );

    return Drawer(
      child: ListView(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(username, style: accountNameTextStyle),
            accountEmail: Text('Transportador', style: accountEmailTextStyle),
            currentAccountPicture: CircleAvatar(
              backgroundImage:
                  profileImage.startsWith('lib/img/')
                      ? AssetImage(profileImage)
                      : NetworkImage(profileImage) as ImageProvider,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pushNamed(context, '/dashboard_transportador');
            },
          ),
          ListTile(
            leading: const Icon(Icons.school),
            title: const Text('Escolas'),
            onTap: () {
              Navigator.pushNamed(context, '/escolas_transportador');
            },
          ),
          ExpansionTile(
            leading: const Icon(Icons.person),
            title: const Text('Alunos'),
            initiallyExpanded: _isAlunosExpanded,
            onExpansionChanged: (expanded) {
              setState(() {
                _isAlunosExpanded = expanded;
              });
            },
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: 30.0,
                ), // Move para a direita
                child: ListTile(
                  leading: const Icon(
                    Icons.edit,
                    size: 20, // Ícone menor
                  ),
                  title: const Text(
                    'Registro',
                    style: TextStyle(fontSize: 14), // Texto menor
                  ),
                  onTap: () {
                    Navigator.pushNamed(context, '/alunos_transportado');
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  left: 30.0,
                ), // Move para a direita
                child: ListTile(
                  leading: const Icon(
                    Icons.update,
                    size: 20, // Ícone menor
                  ),
                  title: const Text(
                    'Reajuste',
                    style: TextStyle(fontSize: 14), // Texto menor
                  ),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/reajuste_transportador',
                    ); // Rota de Reajuste
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  left: 30.0,
                ), // Move para a direita
                child: ListTile(
                  leading: const Icon(
                    Icons.mail,
                    size: 20, // Ícone menor
                  ),
                  title: const Text(
                    'Convite',
                    style: TextStyle(fontSize: 14), // Texto menor
                  ),
                  onTap: () {
                    // Adicionar rota para Convite no futuro
                  },
                ),
              ),
            ],
          ),
          ListTile(
            leading: const Icon(Icons.money),
            title: const Text('Gastos'),
            onTap: () {
              Navigator.pushNamed(context, '/gastos_transportador');
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Avisos de Pagamento'),
            onTap: () {
              Navigator.pushNamed(context, '/avisos_transportador');
            },
          ),
          // A aba "Rastrear" foi removida conforme solicitado.
          ListTile(
            leading: const Icon(Icons.star),
            title: const Text('Assinar'),
            onTap: () {
              Navigator.pushNamed(context, '/assinar_transportador');
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_circle),
            title: const Text('Perfil'),
            onTap: () {
              Navigator.pushNamed(context, '/perfil_transportador');
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              _logout();
            },
          ),
        ],
      ),
    );
  }
}
