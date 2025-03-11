// perfil_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'widgets/transportador_drawer.dart';
import 'package:myapp/theme/theme_provider.dart';
import 'package:myapp/screens/transportador/services/perfil_service.dart';
import 'package:myapp/screens/login_screen.dart'; // Importa a tela de login

class PerfilUsuarioScreen extends StatefulWidget {
  const PerfilUsuarioScreen({super.key});

  @override
  _PerfilUsuarioScreenState createState() => _PerfilUsuarioScreenState();
}

class _PerfilUsuarioScreenState extends State<PerfilUsuarioScreen> {
  String profileImage = 'lib/img/profile/0.png';
  String username = 'Carregando...';
  String email = 'Carregando...';
  String whatsapp = 'Carregando...';
  String pix = 'Carregando...';
  String plano = 'Carregando...';
  String userType = 'Carregando...';

  final PerfilService _perfilService = PerfilService();

  Future<void> _loadUserData() async {
    try {
      final data = await _perfilService.loadUserData();
      if (data != null) {
        print("Dados do usuário: $data");
        setState(() {
          profileImage = 'lib/img/profile/${data['profilePicture'] ?? 0}.png';
          username = data['username'] ?? 'Nome não encontrado';
          email = data['email'] ?? 'E-mail não encontrado';
          whatsapp = data['whatsapp'] ?? 'Whatsapp não encontrado';
          pix = data['pix'] ?? 'Pix não encontrado';
          plano = data['plano'] != null
              ? data['plano'].toString()
              : 'Plano não encontrado';
          userType = data['userType'] ?? 'Tipo não encontrado';
        });
      }
    } catch (e) {
      print("Erro ao carregar dados do usuário: $e");
      setState(() {
        profileImage = 'lib/img/profile/0.png';
        username = 'Erro ao carregar nome';
      });
    }
  }

  Future<void> _updateUserData(String field, String newValue) async {
    try {
      await _perfilService.updateUserData(field, newValue);
      setState(() {
        if (field == 'username') username = newValue;
        if (field == 'whatsapp') whatsapp = newValue;
        if (field == 'pix') pix = newValue;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar $field: $e')));
    }
  }

  Future<void> _updateProfilePicture(int newIndex) async {
    try {
      await _perfilService.updateProfilePicture(newIndex);
      setState(() {
        profileImage = 'lib/img/profile/$newIndex.png';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar a imagem: $e')));
    }
  }

  // Função para exibir a caixa de diálogo de edição
  void _showEditDialog(String field, String currentValue) {
    final TextEditingController controller =
        TextEditingController(text: currentValue);

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Editar ${_getFieldLabel(field)}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Novo ${_getFieldLabel(field)}',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _updateUserData(field, controller.text.trim());
                  Navigator.pop(context);
                },
                child: const Text('Salvar'),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getFieldLabel(String field) {
    switch (field) {
      case 'username':
        return 'Nome';
      case 'whatsapp':
        return 'Whatsapp';
      case 'pix':
        return 'Pix';
      default:
        return 'Campo';
    }
  }

  String _getPlanoDescription(String plano) {
    switch (plano) {
      case '0':
        return 'Grátis';
      case '1':
        return 'Profissional';
      case '2':
        return 'Profissional, Cancelado';
      default:
        return 'Plano não encontrado';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Função para confirmar e executar a exclusão de conta
  void _confirmDeleteAccount() {
    if (plano == '0') {
      // Usuário com plano gratuito: permite exclusão
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Excluir Conta'),
            content: const Text(
              'Tem certeza que deseja excluir sua conta? Essa ação não pode ser desfeita.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context); // fecha o diálogo
                  await _deleteAccount();
                },
                child: const Text(
                  'Excluir',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          );
        },
      );
    } else if (plano == '1') {
      // Usuário com plano profissional ativo: não permite exclusão
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Ação não permitida'),
            content: const Text(
              'Você possui um plano profissional ativo. Cancele o plano antes de excluir sua conta.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } else {
      // Outros casos (por exemplo, plano não encontrado ou cancelado)
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Ação não permitida'),
            content: const Text(
              'Não foi possível excluir sua conta neste momento.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _deleteAccount() async {
    try {
      await _perfilService.deleteAccount();
      // Após excluir a conta, redireciona para a tela de login
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir conta: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = themeProvider.currentTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil do Usuário'),
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header com foto de perfil
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.transparent,
                  child: ClipOval(
                    child: Image.asset(
                      profileImage,
                      fit: BoxFit.cover,
                      width: 120,
                      height: 120,
                    ),
                  ),
                ),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.blue,
                  child: IconButton(
                    icon: const Icon(Icons.edit,
                        size: 16, color: Colors.white),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) {
                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Escolha uma nova imagem de perfil:',
                                  style: TextStyle(fontSize: 16),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 10),
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics:
                                      const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 8.0,
                                    mainAxisSpacing: 8.0,
                                  ),
                                  itemCount: 3,
                                  itemBuilder: (context, index) {
                                    return GestureDetector(
                                      onTap: () {
                                        _updateProfilePicture(index);
                                        Navigator.pop(context);
                                      },
                                      child: CircleAvatar(
                                        radius: 30,
                                        backgroundImage: AssetImage(
                                          'lib/img/profile/$index.png',
                                        ),
                                        backgroundColor: Colors.transparent,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Seção: Dados Pessoais
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              elevation: 5,
              child: ListView(
                shrinkWrap: true,
                children: [
                  _buildListTile('Nome', username, Icons.person, 'username'),
                  _buildListTile('Email', email, Icons.email),
                  _buildListTile(
                      'Whatsapp', whatsapp, Icons.phone, 'whatsapp'),
                  _buildListTile('Pix', pix, Icons.payment, 'pix'),
                  _buildListTile(
                    'Plano',
                    _getPlanoDescription(plano),
                    Icons.card_membership,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Botão discreto para excluir conta, centralizado, com texto em vermelho e sem ícone
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Center(
                child: TextButton(
                  onPressed: _confirmDeleteAccount,
                  child: const Text(
                    'Excluir Conta',
                    style: TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(
    String title,
    String subtitle,
    IconData icon, [
    String? field,
  ]) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: field != null
          ? IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                _showEditDialog(field, subtitle);
              },
            )
          : null,
    );
  }
}
