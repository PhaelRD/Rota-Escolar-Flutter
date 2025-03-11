import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/theme/theme_provider.dart';
import 'package:myapp/screens/login_screen.dart';
import 'package:myapp/screens/transportador/services/avisos_service.dart';
import 'widgets/transportador_drawer.dart';

class AvisosScreen extends StatefulWidget {
  const AvisosScreen({Key? key}) : super(key: key);

  @override
  _AvisosScreenState createState() => _AvisosScreenState();
}

class _AvisosScreenState extends State<AvisosScreen> {
  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;
  List<Map<String, dynamic>> alunos = [];
  bool isLoading = true;

  final AvisosService _avisosService = AvisosService();

  @override
  void initState() {
    super.initState();
    _loadAlunos();
  }

  Future<void> _loadAlunos() async {
    setState(() => isLoading = true);
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      List<Map<String, dynamic>> alunosData =
          await _avisosService.verificarStatusAlunos(selectedYear, selectedMonth);
      setState(() => alunos = alunosData);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Erro ao carregar alunos: $e")));
    }
    setState(() => isLoading = false);
  }

  Future<void> _marcarComoPago(String alunoId) async {
    await _avisosService.salvarPagamento(alunoId, selectedYear, selectedMonth);
    _loadAlunos();
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    String Function(T)? itemLabel,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(
                itemLabel != null ? itemLabel(item) : item.toString(),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pago':
        return Colors.green;
      case 'pendente':
        return Colors.amber;
      case 'atrasado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pago':
        return Icons.check_circle;
      case 'pendente':
        return Icons.access_time;
      case 'atrasado':
        return Icons.error;
      default:
        return Icons.help;
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
        title: const Text('Avisos'),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildDropdownField<int>(
                    label: 'Mês',
                    value: selectedMonth,
                    items: List.generate(12, (i) => i + 1),
                    onChanged: (v) => setState(() {
                      selectedMonth = v!;
                      _loadAlunos();
                    }),
                    itemLabel: (item) => "Mês $item",
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildDropdownField<int>(
                    label: 'Ano',
                    value: selectedYear,
                    items: List.generate(
                      10,
                      (i) => DateTime.now().year - 5 + i,
                    ),
                    onChanged: (v) => setState(() {
                      selectedYear = v!;
                      _loadAlunos();
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : alunos.isEmpty
                      ? const Center(
                          child: Text("Nenhum aluno foi registrado até essa data."),
                        )
                      : ListView.builder(
                          itemCount: alunos.length,
                          itemBuilder: (context, index) {
                            final aluno = alunos[index];
                            final status = aluno['status'] ?? 'desconhecido';
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.person,
                                  color: Colors.blue,
                                ),
                                title: Text(aluno['nomeAluno'] ?? "Sem Nome"),
                                subtitle: Text(
                                  "Responsável: ${aluno['nomeResponsavel'] ?? 'Desconhecido'}\n"
                                  "Telefone: ${aluno['telefone1'] ?? 'Não informado'}",
                                ),
                                trailing: status == 'atrasado'
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              _getStatusIcon(status),
                                              color: _getStatusColor(status),
                                            ),
                                            onPressed: () =>
                                                _marcarComoPago(aluno['id']),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.message,
                                              color: Colors.blue,
                                            ),
                                            onPressed: () =>
                                                _avisosService.enviarCobranca(
                                              context,
                                              aluno['id'],
                                              selectedMonth,
                                            ),
                                          ),
                                        ],
                                      )
                                    : IconButton(
                                        icon: Icon(
                                          _getStatusIcon(status),
                                          color: _getStatusColor(status),
                                        ),
                                        onPressed: (status == 'pendente')
                                            ? () =>
                                                _marcarComoPago(aluno['id'])
                                            : null,
                                      ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
