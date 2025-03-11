import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets/transportador_drawer.dart';
import 'package:myapp/theme/theme_provider.dart';
import 'package:myapp/screens/login_screen.dart';
import 'package:myapp/screens/transportador/services/reajuste_service.dart';

class ReajusteScreen extends StatefulWidget {
  const ReajusteScreen({super.key});

  @override
  State<ReajusteScreen> createState() => _ReajusteScreenState();
}

class _ReajusteScreenState extends State<ReajusteScreen> {
  final ReajusteService _reajusteService = ReajusteService();
  List<Map<String, dynamic>> alunos = [];
  Map<String, bool> selectedAlunos = {};
  bool isLoading = false;
  bool selectAll = false;
  // Novo campo para controlar o envio de e-mails
  bool enviarEmails = false;
  // Variável que indica se o usuário pode enviar e-mails (plano == "1")
  bool _canSendEmails = false;
  final TextEditingController _percentageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> filteredAlunos = [];

  @override
  void initState() {
    super.initState();
    _loadAlunos();
    _loadUserPlan();
  }

  Future<void> _loadUserPlan() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      String? plan = await _reajusteService.getUserPlan(currentUser.uid);
      setState(() {
        // Habilita o envio de e-mails apenas se o plano for "1"
        _canSendEmails = (plan == "1");
        // Caso o usuário não possua o plano adequado, desativa o checkbox
        if (!_canSendEmails) {
          enviarEmails = false;
        }
      });
    }
  }

  Future<void> _loadAlunos() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      setState(() => isLoading = true);
      List<Map<String, dynamic>> result =
          await _reajusteService.getAlunos(currentUser.uid);
      setState(() {
        alunos = result;
        filteredAlunos = List.from(alunos);
        for (var aluno in alunos) {
          selectedAlunos[aluno['alunoId']] = false;
        }
        isLoading = false;
      });
    }
  }

  void _applyReajuste() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      return;
    }

    final List<String> alunoIdsSelecionados = selectedAlunos.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (alunoIdsSelecionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione ao menos um aluno.')),
      );
      return;
    }

    double? reajustePercent = double.tryParse(_percentageController.text);
    if (reajustePercent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Insira um valor válido para o reajuste.')),
      );
      return;
    }

    setState(() => isLoading = true);

    // Aplica o reajuste
    await _reajusteService.aplicarReajuste(
      currentUser.uid,
      alunoIdsSelecionados,
      reajustePercent,
    );

    // Se o checkbox de envio de e-mails estiver ativado, envia as notificações
    if (enviarEmails) {
      await _reajusteService.notificarResponsaveisReajuste(
        currentUser.uid,
        alunoIdsSelecionados,
        reajustePercent,
      );
    }

    setState(() {
      isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reajuste aplicado com sucesso!')),
    );

    _loadAlunos();
  }

  void _filterAlunos(String query) {
    setState(() {
      filteredAlunos = alunos.where((aluno) {
        final nome = aluno['nomeAluno'].toString().toLowerCase();
        final valor = aluno['valorMensalidade'].toString();
        return nome.contains(query.toLowerCase()) || valor.contains(query);
      }).toList();
    });
  }

  void _toggleSelectAll(bool? value) {
    if (value == null) return;
    setState(() {
      selectAll = value;
      for (var aluno in filteredAlunos) {
        selectedAlunos[aluno['alunoId']] = value;
      }
    });
  }

  @override
  void dispose() {
    _percentageController.dispose();
    _searchController.dispose();
    super.dispose();
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
        title: const Text('Reajuste'),
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _percentageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Percentual de reajuste (%)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _searchController,
                    onChanged: _filterAlunos,
                    decoration: const InputDecoration(
                      labelText: 'Pesquisar por nome ou valor',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Checkbox para selecionar todos os alunos
                  CheckboxListTile(
                    title: const Text('Selecionar Todos'),
                    value: selectAll,
                    onChanged: _toggleSelectAll,
                  ),
                  // Checkbox para ativar/desativar o envio de e-mails:
                  // O callback onChanged fica null se o usuário não tiver o plano adequado.
                  CheckboxListTile(
                    title: const Text('Enviar e-mails de notificação'),
                    value: enviarEmails,
                    onChanged: _canSendEmails
                        ? (bool? value) {
                            if (value == null) return;
                            setState(() {
                              enviarEmails = value;
                            });
                          }
                        : null,
                    // Opcional: exibe um subtítulo informando que a opção está disponível somente para o plano 1
                    subtitle: _canSendEmails
                        ? null
                        : const Text(
                            'Disponível apenas para o plano Profissional',
                            style: TextStyle(color: Colors.red),
                          ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredAlunos.length,
                    itemBuilder: (context, index) {
                      final aluno = filteredAlunos[index];
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: const Icon(Icons.person, color: Colors.blue),
                          title: Text(
                            aluno['nomeAluno'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                              'Valor atual: R\$ ${aluno['valorMensalidade']}'),
                          trailing: Checkbox(
                            value: selectedAlunos[aluno['alunoId']] ?? false,
                            onChanged: (bool? value) {
                              setState(() {
                                selectedAlunos[aluno['alunoId']] =
                                    value ?? false;
                                selectAll =
                                    selectedAlunos.values.every((e) => e);
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _applyReajuste,
                    child: const Text('Aplicar Reajuste'),
                  ),
                ],
              ),
            ),
    );
  }
}
