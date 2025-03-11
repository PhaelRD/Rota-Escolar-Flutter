import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets/transportador_drawer.dart';
import 'package:myapp/theme/theme_provider.dart';
import 'package:myapp/screens/login_screen.dart';
import 'package:myapp/screens/transportador/services/alunos_service.dart';

class AlunosScreen extends StatefulWidget {
  const AlunosScreen({super.key});

  @override
  State<AlunosScreen> createState() => _AlunosScreenState();
}

class _AlunosScreenState extends State<AlunosScreen> {
  late Future<List<Map<String, dynamic>>> _alunos;
  late Future<String> _alunosInfo;
  late Future<Map<String, String>> _escolas;

  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredAlunos = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
    _searchController.addListener(_filterAlunos);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Atualiza as variáveis que carregam os dados e força a reconstrução da tela
  void _fetchData() {
    final alunosService = AlunosService();
    _alunos = alunosService.listarAlunos();
    _alunosInfo = _fetchAlunosInfo(alunosService);
    _escolas = alunosService.buscarEscolas();
  }

  // Método auxiliar para atualizar a informação de limite e quantidade de alunos
  Future<String> _fetchAlunosInfo(AlunosService alunosService) async {
    try {
      final maxAlunos = await alunosService.verificarLimiteAlunos();
      final alunosRegistrados = await alunosService.contarAlunosRegistrados();
      return '$alunosRegistrados/$maxAlunos';
    } catch (e) {
      return 'Erro ao carregar dados.';
    }
  }

  // Apenas reinicia a lista filtrada (o filtro será aplicado no FutureBuilder)
  void _filterAlunos() {
    setState(() {
      _filteredAlunos = [];
    });
  }

  // Permite atualizar os dados via pull-to-refresh ou após operações (edição/adicionar/excluir)
  Future<void> _refreshData() async {
    setState(() {
      _fetchData();
    });
  }

  void _openCadastroAlunoDialog({Map<String, dynamic>? aluno}) async {
    final alunosService = AlunosService();
    final escolas = await alunosService.buscarEscolas();

    if (escolas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma escola cadastrada.')),
      );
      return;
    }

    final alunosInfo = await _alunosInfo;
    final partes = alunosInfo.split('/');
    final alunosRegistrados = int.parse(partes[0].trim());
    final maxAlunos = int.parse(partes[1].trim());

    if (alunosRegistrados >= maxAlunos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Número máximo de alunos atingido.')),
      );
      return;
    }

    // Controllers e variáveis
    String? selectedEscolaId = aluno?['idEscola'];
    String? selectedPeriodo = aluno?['periodo'];
    final TextEditingController nomeController = TextEditingController(
      text: aluno?['nomeAluno'],
    );
    final TextEditingController idadeController = TextEditingController(
      text: aluno?['idadeAluno']?.toString(),
    );
    final TextEditingController valorController = TextEditingController(
      text: aluno?['valorMensalidade']?.toString(),
    );
    final TextEditingController vencimentoController = TextEditingController(
      text: aluno?['dataVencimento'],
    );
    final TextEditingController responsavelController = TextEditingController(
      text: aluno?['nomeResponsavel'],
    );
    final TextEditingController telefone1Controller = TextEditingController();
    final TextEditingController telefone2Controller = TextEditingController();
    final TextEditingController emailController = TextEditingController(
      text: aluno?['emailResponsavel'],
    );
    final TextEditingController retiradaController = TextEditingController(
      text: aluno?['enderecoRetirada'],
    );
    final TextEditingController entregaController = TextEditingController(
      text: aluno?['enderecoEntrega'],
    );

    String selectedDDD1 = '11';
    String selectedDDD2 = '11';

    if (aluno != null) {
      final tel1 = aluno['telefone1'];
      if (tel1 != null && tel1.toString().length >= 2) {
        selectedDDD1 = tel1.toString().substring(0, 2);
        telefone1Controller.text = tel1.toString().substring(2);
      }
      final tel2 = aluno['telefone2'];
      if (tel2 != null && tel2.toString().length >= 2) {
        selectedDDD2 = tel2.toString().substring(0, 2);
        telefone2Controller.text = tel2.toString().substring(2);
      }
    }

    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        int currentStep = 0;
        final int totalSteps = 6;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 16.0,
                left: 16.0,
                right: 16.0,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      aluno == null ? 'Registrar Aluno' : 'Editar Aluno',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
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
                    // Conteúdo das etapas
                    if (currentStep == 0) ...[
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Escola'),
                        value: selectedEscolaId,
                        items:
                            escolas.entries.map((entry) {
                              return DropdownMenuItem<String>(
                                value: entry.key,
                                child: Text(entry.value),
                              );
                            }).toList(),
                        onChanged: (value) => selectedEscolaId = value,
                        validator: (value) {
                          if (value == null) {
                            return 'Por favor, selecione uma escola.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Período'),
                        value: selectedPeriodo,
                        items:
                            ['Manhã', 'Tarde', 'Noite'].map((periodo) {
                              return DropdownMenuItem<String>(
                                value: periodo,
                                child: Text(periodo),
                              );
                            }).toList(),
                        onChanged: (value) => selectedPeriodo = value,
                        validator: (value) {
                          if (value == null) {
                            return 'Por favor, selecione um período.';
                          }
                          return null;
                        },
                      ),
                    ] else if (currentStep == 1) ...[
                      TextFormField(
                        controller: nomeController,
                        decoration: const InputDecoration(
                          labelText: 'Nome do Aluno',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, insira o nome do aluno.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: idadeController,
                        decoration: const InputDecoration(
                          labelText: 'Idade do Aluno',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, insira a idade do aluno.';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Idade inválida.';
                          }
                          return null;
                        },
                      ),
                    ] else if (currentStep == 2) ...[
                      TextFormField(
                        controller: valorController,
                        decoration: const InputDecoration(
                          labelText: 'Valor da Mensalidade',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, insira o valor da mensalidade.';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Valor inválido.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: vencimentoController,
                        decoration: const InputDecoration(
                          labelText: 'Data de Vencimento',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, insira a data de vencimento.';
                          }
                          return null;
                        },
                      ),
                    ] else if (currentStep == 3) ...[
                      // Telefone e DDD
                      Row(
                        children: [
                          SizedBox(
                            width: 80,
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'DDD',
                              ),
                              value: selectedDDD1,
                              items:
                                  ['11', '21', '31', '41', '51']
                                      .map(
                                        (ddd) => DropdownMenuItem(
                                          value: ddd,
                                          child: Text(ddd),
                                        ),
                                      )
                                      .toList(),
                              onChanged:
                                  (value) =>
                                      setState(() => selectedDDD1 = value!),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: telefone1Controller,
                              decoration: const InputDecoration(
                                labelText: 'Telefone 1',
                              ),
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor, insira o telefone 1.';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          SizedBox(
                            width: 80,
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'DDD',
                              ),
                              value: selectedDDD2,
                              items:
                                  ['11', '21', '31', '41', '51']
                                      .map(
                                        (ddd) => DropdownMenuItem(
                                          value: ddd,
                                          child: Text(ddd),
                                        ),
                                      )
                                      .toList(),
                              onChanged:
                                  (value) =>
                                      setState(() => selectedDDD2 = value!),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: telefone2Controller,
                              decoration: const InputDecoration(
                                labelText: 'Telefone 2',
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                        ],
                      ),
                    ] else if (currentStep == 4) ...[
                      TextFormField(
                        controller: responsavelController,
                        decoration: const InputDecoration(
                          labelText: 'Nome do Responsável',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, insira o nome do responsável.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email do Responsável',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, insira o email do responsável.';
                          }
                          if (!RegExp(
                            r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$",
                          ).hasMatch(value)) {
                            return 'Email inválido.';
                          }
                          return null;
                        },
                      ),
                    ] else if (currentStep == 5) ...[
                      TextFormField(
                        controller: retiradaController,
                        decoration: const InputDecoration(
                          labelText: 'Endereço de Retirada',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, insira o endereço de retirada.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: entregaController,
                        decoration: const InputDecoration(
                          labelText: 'Endereço de Entrega',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, insira o endereço de entrega.';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState?.validate() ?? false) {
                          if (currentStep < totalSteps - 1) {
                            setState(() => currentStep++);
                          } else {
                            try {
                              final telefone1Completo =
                                  '$selectedDDD1${telefone1Controller.text.trim()}';
                              final telefone2Completo =
                                  '$selectedDDD2${telefone2Controller.text.trim()}';

                              if (aluno == null) {
                                await alunosService.registrarAluno(
                                  idEscola: selectedEscolaId!,
                                  nomeAluno: nomeController.text,
                                  idadeAluno: int.parse(
                                    idadeController.text.trim(),
                                  ),
                                  valorMensalidade: double.parse(
                                    valorController.text.trim(),
                                  ),
                                  dataVencimento:
                                      vencimentoController.text.trim(),
                                  periodo: selectedPeriodo!,
                                  nomeResponsavel: responsavelController.text,
                                  telefone1: telefone1Completo,
                                  telefone2: telefone2Completo,
                                  emailResponsavel: emailController.text,
                                  enderecoRetirada: retiradaController.text,
                                  enderecoEntrega: entregaController.text,
                                );
                              } else {
                                await alunosService.editarAluno(
                                  alunoId: aluno['id'],
                                  idEscola: selectedEscolaId!,
                                  nomeAluno: nomeController.text,
                                  idadeAluno: int.parse(
                                    idadeController.text.trim(),
                                  ),
                                  valorMensalidade: double.parse(
                                    valorController.text.trim(),
                                  ),
                                  dataVencimento:
                                      vencimentoController.text.trim(),
                                  periodo: selectedPeriodo!,
                                  nomeResponsavel: responsavelController.text,
                                  telefone1: telefone1Completo,
                                  telefone2: telefone2Completo,
                                  emailResponsavel: emailController.text,
                                  enderecoRetirada: retiradaController.text,
                                  enderecoEntrega: entregaController.text,
                                );
                              }

                              Navigator.pop(context);
                              _refreshData();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    aluno == null
                                        ? 'Aluno registrado com sucesso!'
                                        : 'Aluno atualizado com sucesso!',
                                  ),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Erro ao salvar: $e')),
                              );
                            }
                          }
                        }
                      },
                      child: Text(
                        currentStep < totalSteps - 1 ? 'Próximo' : 'Salvar',
                      ),
                    ),
                    if (currentStep > 0)
                      TextButton(
                        onPressed: () => setState(() => currentStep--),
                        child: const Text('Voltar'),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Método para excluir aluno e atualizar a lista com confirmação
  Future<void> _excluirAluno(String alunoId) async {
    final alunosService = AlunosService();

    // Exibe um diálogo de confirmação
    bool? confirmacao = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: const Text('Tem certeza de que deseja excluir este aluno?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).pop(false); // O usuário escolheu "Cancelar"
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).pop(true); // O usuário escolheu "Confirmar"
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );

    if (confirmacao == true) {
      try {
        // Exclui o aluno e atualiza a lista
        await alunosService.excluirAluno(alunoId);
        _refreshData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aluno excluído com sucesso.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao excluir aluno: $e')));
      }
    }
  }

  // Função para abrir o WhatsApp com a opção de escolher entre os dois contatos
  void _openWhatsAppOptions(Map<String, dynamic> aluno) async {
    final alunosService = AlunosService();
    final telefone1 = aluno['telefone1']?.toString() ?? '';
    final telefone2 = aluno['telefone2']?.toString() ?? '';

    if (telefone1.isNotEmpty && telefone2.isNotEmpty) {
      // Exibe um diálogo para escolher qual contato utilizar
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Escolha o contato"),
            content: const Text("Selecione qual número abrir no WhatsApp."),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  try {
                    await alunosService.abrirWhatsappAluno(
                      aluno['id'],
                      contatoSelecionado: 1,
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro ao abrir WhatsApp: $e')),
                    );
                  }
                },
                child: const Text("Telefone 1"),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  try {
                    await alunosService.abrirWhatsappAluno(
                      aluno['id'],
                      contatoSelecionado: 2,
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro ao abrir WhatsApp: $e')),
                    );
                  }
                },
                child: const Text("Telefone 2"),
              ),
            ],
          );
        },
      );
    } else if (telefone1.isNotEmpty) {
      try {
        await alunosService.abrirWhatsappAluno(
          aluno['id'],
          contatoSelecionado: 1,
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao abrir WhatsApp: $e')));
      }
    } else if (telefone2.isNotEmpty) {
      try {
        await alunosService.abrirWhatsappAluno(
          aluno['id'],
          contatoSelecionado: 2,
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao abrir WhatsApp: $e')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nenhum contato disponível")),
      );
    }
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
        title: const Text('Alunos'),
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
      // Utiliza RefreshIndicator para atualizar a lista com pull-to-refresh
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                // Barra de pesquisa
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: 'Pesquisar por nome',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 20),
                FutureBuilder<String>(
                  future: _alunosInfo,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return const Text(
                        'Erro ao carregar informações.',
                        style: TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      );
                    } else {
                      final alunosInfo = snapshot.data!;
                      final partes = alunosInfo.split('/');
                      final alunosRegistrados = int.parse(partes[0].trim());
                      final maxAlunos = int.parse(partes[1].trim());
                      final cor =
                          alunosRegistrados == maxAlunos
                              ? Colors.red
                              : Colors.green;

                      return Align(
                        alignment: Alignment.topRight,
                        child: Text(
                          '$alunosRegistrados / $maxAlunos',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: cor,
                          ),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 20),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _alunos,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError || snapshot.data == null) {
                      return const Text(
                        'Erro ao carregar lista de alunos.',
                        style: TextStyle(color: Colors.red),
                      );
                    } else if (snapshot.data!.isEmpty) {
                      return const Text('Nenhum aluno registrado.');
                    } else {
                      // Aplica o filtro conforme o texto da busca
                      _filteredAlunos =
                          snapshot.data!
                              .where(
                                (aluno) =>
                                    aluno['nomeAluno'].toLowerCase().contains(
                                      _searchController.text.toLowerCase(),
                                    ),
                              )
                              .toList();

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _filteredAlunos.length,
                        itemBuilder: (context, index) {
                          final aluno = _filteredAlunos[index];
                          final nomeEscola =
                              aluno['nomeEscola'] ?? 'Escola não informada';
                          final telefoneResponsavel =
                              aluno['telefone1'] ?? 'Não informado';

                          return Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              leading: const Icon(
                                Icons.person,
                                color: Colors.blue,
                              ),
                              title: Text(
                                aluno['nomeAluno'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Escola: $nomeEscola | Responsável: ${aluno['nomeResponsavel']} | Contato: $telefoneResponsavel',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Botão para abrir o WhatsApp com as opções de contato
                                  IconButton(
                                    icon: const Icon(
                                      Icons.chat,
                                      color: Colors.green,
                                    ),
                                    onPressed:
                                        () => _openWhatsAppOptions(aluno),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed:
                                        () => _openCadastroAlunoDialog(
                                          aluno: aluno,
                                        ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _excluirAluno(aluno['id']),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCadastroAlunoDialog(),
        backgroundColor: currentTheme.colorScheme.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
