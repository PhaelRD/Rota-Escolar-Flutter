import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets/transportador_drawer.dart';
import 'package:myapp/theme/theme_provider.dart';
import 'package:myapp/screens/login_screen.dart';
import 'package:myapp/screens/transportador/services/escolas_service.dart';

class EscolasScreen extends StatefulWidget {
  const EscolasScreen({super.key});

  @override
  _EscolasScreenState createState() => _EscolasScreenState();
}

class _EscolasScreenState extends State<EscolasScreen> {
  final EscolasService escolasService = EscolasService();
  late Future<List<Map<String, dynamic>>> escolasList;
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadEscolas();
  }

  // Função para carregar as escolas (com pesquisa opcional)
  void _loadEscolas({String query = ""}) {
    setState(() {
      if (query.isEmpty) {
        escolasList = escolasService.getListaEscolas();
      } else {
        escolasList = escolasService.pesquisarEscolaPorNome(query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      // Redireciona para a tela de login se o usuário não estiver autenticado
      Future.microtask(() {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      });
      return const SizedBox(); // Widget vazio temporariamente
    }

    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = themeProvider.currentTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Escolas'),
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            // Barra de pesquisa
            TextField(
              onChanged: (value) {
                searchQuery = value;
                _loadEscolas(query: searchQuery);
              },
              decoration: InputDecoration(
                labelText: 'Pesquisar Escola',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Widget para exibir a quantidade de escolas
            FutureBuilder<List<dynamic>>(
              future: Future.wait([
                escolasService.getMaxEscolas(),
                escolasService.getNumeroDeEscolas(),
              ]),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Text('Erro: ${snapshot.error}');
                } else if (snapshot.hasData) {
                  final maxEscolas = snapshot.data![0];
                  final numeroDeEscolas = snapshot.data![1];
                  return Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16.0, bottom: 16.0),
                      child: Text(
                        '$numeroDeEscolas/$maxEscolas',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color:
                              numeroDeEscolas >= maxEscolas
                                  ? Colors.red
                                  : Colors.green,
                        ),
                      ),
                    ),
                  );
                } else {
                  return const SizedBox();
                }
              },
            ),
            // Exibindo a lista de escolas
            FutureBuilder<List<Map<String, dynamic>>>(
              future: escolasList,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Text('Erro: ${snapshot.error}');
                } else if (snapshot.hasData) {
                  final escolas = snapshot.data!;
                  if (escolas.isEmpty) {
                    return const Center(
                      child: Text('Nenhuma escola registrada.'),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: escolas.length,
                    itemBuilder: (context, index) {
                      final escola = escolas[index];
                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: const Icon(Icons.school, color: Colors.blue),
                          title: Text(
                            escola['nome'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Endereço: ${escola['endereco']} | Contato: ${escola['contato']}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Botão para abrir o WhatsApp
                              IconButton(
                                icon: const Icon(
                                  Icons.chat,
                                  color: Colors.green,
                                ),
                                onPressed: () async {
                                  try {
                                    await escolasService.abrirWhatsapp(
                                      escola['id'],
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Erro ao abrir o WhatsApp: $e',
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  _showRegistrarEscolaDialog(
                                    context,
                                    escolaId: escola['id'],
                                    nome: escola['nome'],
                                    endereco: escola['endereco'],
                                    contato: escola['contato'],
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  _confirmDelete(context, escola['id']);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                } else {
                  return const Center(
                    child: Text('Nenhuma escola registrada.'),
                  );
                }
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showRegistrarEscolaDialog(context),
        backgroundColor: currentTheme.colorScheme.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  // Janela flutuante em modo wizard para registrar ou editar escola
  void _showRegistrarEscolaDialog(
    BuildContext context, {
    String? escolaId,
    String? nome,
    String? endereco,
    String? contato,
  }) async {
    // Obtendo os limites de cadastro
    final maxEscolas = await escolasService.getMaxEscolas();
    final numeroDeEscolas = await escolasService.getNumeroDeEscolas();
    if (numeroDeEscolas >= maxEscolas) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Número máximo de escolas atingido. Você pode registrar até $maxEscolas escolas.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Controllers para os campos
    final nomeController = TextEditingController(text: nome);
    final enderecoController = TextEditingController(text: endereco);
    final contatoController = TextEditingController(text: contato);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        // Variável para o código de área e controle de etapas
        String selectedAreaCode = '11';
        int currentStep = 0;
        final int totalSteps = 3;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 16.0,
                left: 16.0,
                right: 16.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    escolaId == null ? 'Registrar Escola' : 'Editar Escola',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  // Barra de progresso indicando a etapa atual
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    tween: Tween<double>(
                      begin: 0,
                      end: (currentStep + 1) / totalSteps,
                    ),
                    builder: (context, value, child) {
                      return LinearProgressIndicator(
                        value: value,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  // Exibe o campo conforme a etapa atual
                  if (currentStep == 0) ...[
                    TextField(
                      controller: nomeController,
                      decoration: const InputDecoration(
                        labelText: 'Nome da Escola',
                      ),
                    ),
                  ] else if (currentStep == 1) ...[
                    TextField(
                      controller: enderecoController,
                      decoration: const InputDecoration(
                        labelText: 'Endereço da Escola',
                      ),
                    ),
                  ] else if (currentStep == 2) ...[
                    Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(labelText: 'DDD'),
                            value: selectedAreaCode,
                            items:
                                ['11', '21', '31', '41', '51']
                                    .map(
                                      (code) => DropdownMenuItem<String>(
                                        value: code,
                                        child: Text(code),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedAreaCode = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: contatoController,
                            decoration: const InputDecoration(
                              labelText: 'Contato',
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  // Botão principal: "Próximo" nas etapas intermediárias ou "Salvar" na última
                  ElevatedButton(
                    onPressed: () async {
                      if (currentStep < totalSteps - 1) {
                        // Validação simples por etapa
                        bool valid = false;
                        if (currentStep == 0) {
                          valid = nomeController.text.trim().isNotEmpty;
                        } else if (currentStep == 1) {
                          valid = enderecoController.text.trim().isNotEmpty;
                        }
                        if (valid) {
                          setState(() {
                            currentStep++;
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Por favor, preencha o campo obrigatório.',
                              ),
                            ),
                          );
                        }
                      } else {
                        // Última etapa: coleta e valida todos os dados
                        final nomeText = nomeController.text.trim();
                        final enderecoText = enderecoController.text.trim();
                        final contatoText = contatoController.text.trim();

                        // Verifica se o número de contato começa com "11" e remove
                        String contatoFinal = contatoText;
                        if (contatoFinal.startsWith('11')) {
                          contatoFinal = contatoFinal.substring(
                            2,
                          ); // Remove o "11"
                        }

                        final contatoCompleto =
                            '$selectedAreaCode$contatoFinal';

                        if (nomeText.isNotEmpty &&
                            enderecoText.isNotEmpty &&
                            contatoCompleto.isNotEmpty &&
                            selectedAreaCode.isNotEmpty) {
                          try {
                            if (escolaId == null) {
                              await escolasService.registrarEscola(
                                nome: nomeText,
                                endereco: enderecoText,
                                contato: contatoCompleto,
                              );
                            } else {
                              await escolasService.editarEscola(
                                escolaId,
                                nomeText,
                                enderecoText,
                                contatoCompleto,
                              );
                            }
                            Navigator.pop(context);
                            _loadEscolas();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Escola registrada/atualizada com sucesso!',
                                ),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text('Erro: $e')));
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Todos os campos são obrigatórios.',
                              ),
                            ),
                          );
                        }
                      }
                    },
                    child: Text(
                      currentStep < totalSteps - 1 ? 'Próximo' : 'Salvar',
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (currentStep > 0)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          currentStep--;
                        });
                      },
                      child: const Text('Voltar'),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Função para confirmar a exclusão da escola
  void _confirmDelete(BuildContext context, String escolaId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir Escola'),
          content: const Text('Tem certeza que deseja excluir esta escola?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await escolasService.excluirEscola(escolaId);
                  Navigator.pop(context);
                  _loadEscolas();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Escola excluída com sucesso!'),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Erro: $e')));
                }
              },
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );
  }
}
