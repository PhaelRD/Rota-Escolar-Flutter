import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:myapp/theme/theme_provider.dart';
import 'package:myapp/screens/login_screen.dart';
import 'package:myapp/screens/transportador/services/gastos_service.dart';
import 'widgets/transportador_drawer.dart';
import 'package:flutter/services.dart';

class GastosScreen extends StatefulWidget {
  const GastosScreen({Key? key}) : super(key: key);

  @override
  _GastosScreenState createState() => _GastosScreenState();
}

class _GastosScreenState extends State<GastosScreen> {
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  /// Consulta o limite de gastos do usuário com base no plano.
  /// Plano 0 = 5 gastos/mês, Plano 1 = 50 gastos/mês.
  Future<int> _getGastoLimit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;
    final DatabaseReference planRef = FirebaseDatabase.instance.ref(
      'users/${user.uid}/userInfos/plano',
    );
    final snapshot = await planRef.get();
    if (!snapshot.exists) {
      throw Exception("Plano do usuário não encontrado");
    }
    final plan = snapshot.value;
    if (plan == 0) return 5;
    if (plan == 1) return 50;
    throw Exception("Plano inválido");
  }

  /// Retorna uma string formatada com a contagem de gastos e o limite.
  Future<String> _getGastosInfo(List<Map<String, dynamic>> gastos) async {
    final limite = await _getGastoLimit();
    final currentCount = gastos.length;
    return "$currentCount/$limite";
  }

  Widget _getCategoryIcon(String category) {
    const icons = {
      'mecânico': Icon(Icons.build, color: Colors.blue),
      'peças': Icon(Icons.memory, color: Colors.orange),
      'gasolina': Icon(Icons.local_gas_station, color: Colors.green),
      'ajudante': Icon(Icons.person, color: Colors.purple),
      'garagem': Icon(Icons.home_repair_service, color: Colors.brown),
      'outros': Icon(Icons.category, color: Colors.grey),
    };
    return icons[category] ?? const Icon(Icons.more_horiz, color: Colors.grey);
  }

  Future<void> _showGastoDialog(
    BuildContext context, {
    required String title,
    Map<String, dynamic>? gasto,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _GastoFormDialog(
        title: title,
        initialDescription: gasto?['description'],
        initialDate: gasto != null
            ? DateTime(gasto['year'], gasto['month'], gasto['day'])
            : null,
        initialCategory: gasto?['category'] ?? 'mecânico',
        initialValue: gasto?['value'],
        onSave: (description, date, category, value) async {
          if (gasto == null) {
            await GastosService().createGasto(
              description: description,
              day: date.day,
              month: date.month,
              year: date.year,
              category: category,
              value: value,
            );
          } else {
            await GastosService().updateGasto(
              gastoId: gasto['id'],
              description: description,
              day: date.day,
              month: date.month,
              year: date.year,
              category: category,
              value: value,
            );
          }
        },
      ),
    );
  }

  Future<void> _confirmDeleteGasto(BuildContext context, String gastoId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Excluir Gasto"),
        content: const Text("Tem certeza que deseja excluir este gasto?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Excluir"),
          ),
        ],
      ),
    );
    if (confirm == true) {
      _deleteGasto(gastoId);
    }
  }

  Future<void> _deleteGasto(String gastoId) async {
    try {
      await GastosService().deleteGasto(gastoId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gasto excluído com sucesso")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao excluir gasto: $e")),
      );
    }
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    String Function(T)? itemLabel,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          onChanged: onChanged,
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    itemLabel != null ? itemLabel(item) : item.toString(),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      Future.microtask(() {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      });
      return const SizedBox();
    }

    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = themeProvider.currentTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gastos'),
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
          children: [
            // Seletor de mês e ano
            Row(
              children: [
                Expanded(
                  child: _buildDropdownField<int>(
                    label: 'Mês',
                    value: selectedMonth,
                    items: List.generate(12, (i) => i + 1),
                    onChanged: (v) => setState(() => selectedMonth = v!),
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
                    onChanged: (v) => setState(() => selectedYear = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Stream de gastos filtrados pelo mês e ano
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: GastosService().getGastosStream(
                  month: selectedMonth,
                  year: selectedYear,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("Erro: ${snapshot.error}"));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text("Nenhum gasto encontrado."),
                    );
                  }

                  final gastos = snapshot.data!;
                  final total = gastos.fold<double>(
                    0.0,
                    (prev, element) =>
                        prev + (element['value'] as num).toDouble(),
                  );

                  return Column(
                    children: [
                      // Total de gastos (agora vem primeiro)
                      Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          title: const Text(
                            "Total de Gastos",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          trailing: Text(
                            "R\$ ${total.toStringAsFixed(2)}",
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      // Contador de gastos (agora vem depois do total)
                      FutureBuilder<String>(
                        future: _getGastosInfo(gastos),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }
                          if (snapshot.hasError) {
                            return const Text(
                              'Erro ao carregar limite',
                              style: TextStyle(color: Colors.red),
                            );
                          }

                          final parts = snapshot.data!.split('/');
                          final current = int.parse(parts[0]);
                          final max = int.parse(parts[1]);

                          return Card(
                            elevation: 0, // Remove a sombra
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    "$current / $max",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: current >= max
                                          ? Colors.red
                                          : Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      // Lista de gastos
                      Expanded(
                        child: ListView.builder(
                          itemCount: gastos.length,
                          itemBuilder: (context, index) {
                            final gasto = gastos[index];
                            return Card(
                              child: ListTile(
                                leading: _getCategoryIcon(
                                  gasto['category'] ?? '',
                                ),
                                title: Text(gasto['description'] ?? ''),
                                subtitle: Text(
                                  "${gasto['day']}/${gasto['month']}/${gasto['year']} - ${gasto['category']} - R\$ ${gasto['value']}",
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => _showGastoDialog(
                                        context,
                                        title: "Editar Gasto",
                                        gasto: gasto,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () => _confirmDeleteGasto(
                                        context,
                                        gasto['id'],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showGastoDialog(context, title: "Novo Gasto"),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _GastoFormDialog extends StatefulWidget {
  final String title;
  final String? initialDescription;
  final DateTime? initialDate;
  final String initialCategory;
  final double? initialValue;
  final Future<void> Function(
    String description,
    DateTime date,
    String category,
    double value,
  )
  onSave;

  const _GastoFormDialog({
    Key? key,
    required this.title,
    this.initialDescription,
    this.initialDate,
    required this.initialCategory,
    this.initialValue,
    required this.onSave,
  }) : super(key: key);

  @override
  __GastoFormDialogState createState() => __GastoFormDialogState();
}

class __GastoFormDialogState extends State<_GastoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  late TextEditingController _valueController;
  DateTime? _selectedDate;
  late String _selectedCategory;
  bool _isLoading = false;
  int _currentStep = 0;
  final int _totalSteps = 2;

  String? _descriptionError;
  String? _dateError;
  String? _categoryError;
  String? _valueError;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.initialDescription,
    );
    _valueController = TextEditingController(
      text: widget.initialValue?.toString() ?? '',
    );
    _selectedDate = widget.initialDate;
    _selectedCategory = widget.initialCategory;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _validateCurrentStep() {
    setState(() {
      _descriptionError = null;
      _dateError = null;
      _categoryError = null;
      _valueError = null;

      switch (_currentStep) {
        case 0:
          if (_descriptionController.text.isEmpty)
            _descriptionError = 'Preencha a descrição';
          if (_selectedDate == null) _dateError = 'Selecione a data';
          break;
        case 1:
          if (_selectedCategory.isEmpty)
            _categoryError = 'Selecione a categoria';
          if (_valueController.text.isEmpty) _valueError = 'Preencha o valor';
          if (double.tryParse(_valueController.text) == null)
            _valueError = 'Valor inválido';
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 16,
        left: 16,
        right: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            tween: Tween<double>(
              begin: 0,
              end: (_currentStep + 1) / _totalSteps,
            ),
            builder:
                (context, value, child) => LinearProgressIndicator(
                  value: value,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
          ),
          const SizedBox(height: 20),
          Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              children: [
                if (_currentStep == 0) ...[
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: "Descrição",
                      border: const OutlineInputBorder(),
                      errorText: _descriptionError,
                      errorMaxLines: 2,
                    ),
                    validator: (value) {
                      if (value!.isEmpty) return 'Campo obrigatório';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    readOnly: true,
                    controller: TextEditingController(
                      text:
                          _selectedDate != null
                              ? "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}"
                              : "",
                    ),
                    decoration: InputDecoration(
                      labelText: "Data",
                      border: const OutlineInputBorder(),
                      suffixIcon: const Icon(Icons.calendar_today),
                      errorText: _dateError,
                    ),
                    onTap: _pickDate,
                    validator: (value) {
                      if (_selectedDate == null) return 'Campo obrigatório';
                      return null;
                    },
                  ),
                ],
                if (_currentStep == 1) ...[
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: "Categoria",
                      border: const OutlineInputBorder(),
                      errorText: _categoryError,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'mecânico',
                        child: Text('Mecânico'),
                      ),
                      DropdownMenuItem(value: 'peças', child: Text('Peças')),
                      DropdownMenuItem(
                        value: 'gasolina',
                        child: Text('Gasolina'),
                      ),
                      DropdownMenuItem(
                        value: 'ajudante',
                        child: Text('Ajudante'),
                      ),
                      DropdownMenuItem(
                        value: 'garagem',
                        child: Text('Garagem'),
                      ),
                      DropdownMenuItem(value: 'outros', child: Text('Outros')),
                    ],
                    validator: (value) {
                      if (value == null) return 'Selecione uma categoria';
                      return null;
                    },
                    onChanged:
                        (value) => setState(() => _selectedCategory = value!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _valueController,
                    decoration: InputDecoration(
                      labelText: "Valor",
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.attach_money),
                      errorText: _valueError,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                    validator: (value) {
                      if (value!.isEmpty) return 'Campo obrigatório';
                      if (double.tryParse(value) == null)
                        return 'Valor inválido';
                      return null;
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    _validateCurrentStep();
                    if (_descriptionError != null ||
                        _dateError != null ||
                        _categoryError != null ||
                        _valueError != null) {
                      return;
                    }
                    if (_currentStep < _totalSteps - 1) {
                      setState(() => _currentStep++);
                    } else {
                      if (!_formKey.currentState!.validate()) return;
                      setState(() => _isLoading = true);
                      try {
                        await widget.onSave(
                          _descriptionController.text.trim(),
                          _selectedDate!,
                          _selectedCategory,
                          double.parse(_valueController.text),
                        );
                        Navigator.pop(context);
                      } catch (e) {
                        // Se o erro for por limite atingido, exibe um AlertDialog
                        if (e.toString().contains(
                          "Limite de gastos atingido",
                        )) {
                          showDialog(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: const Text("Limite atingido"),
                                  content: const Text(
                                    "Você atingiu o limite de registros de gastos para o seu plano.",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text("OK"),
                                    ),
                                  ],
                                ),
                          );
                        } else {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text("Erro: $e")));
                        }
                      } finally {
                        if (mounted) setState(() => _isLoading = false);
                      }
                    }
                  },
                  child:
                      _isLoading
                          ? const CircularProgressIndicator()
                          : Text(
                            _currentStep < _totalSteps - 1
                                ? 'Próximo'
                                : 'Salvar',
                          ),
                ),
              ),
              const SizedBox(height: 12),
              if (_currentStep > 0)
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => setState(() => _currentStep--),
                    child: const Text('Voltar'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
