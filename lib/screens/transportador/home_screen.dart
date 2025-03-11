import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets/transportador_drawer.dart';
import 'package:myapp/theme/theme_provider.dart';
import 'package:myapp/screens/login_screen.dart';
import 'package:myapp/screens/transportador/widgets/home_service_valores_recebidos.dart';
import 'package:myapp/screens/transportador/widgets/home_service_valores_recebido_por_escola.dart';
import 'package:myapp/screens/transportador/widgets/home_service_receita_por_periodo.dart';
import 'package:myapp/screens/transportador/widgets/home_service_gastos_mensais.dart';
import 'package:myapp/screens/transportador/widgets/home_service_gastos_categorias.dart';
import 'package:myapp/screens/transportador/widgets/home_service_recebido_gastos.dart';
import 'package:fl_chart/fl_chart.dart';

class TransportadorHomeScreen extends StatefulWidget {
  const TransportadorHomeScreen({Key? key}) : super(key: key);

  @override
  _TransportadorHomeScreenState createState() =>
      _TransportadorHomeScreenState();
}

class _TransportadorHomeScreenState extends State<TransportadorHomeScreen> {
  // Dados para Pagamentos e Mensalidades (Receitas)
  late Future<List<BarChartGroupData>> _chartData;
  late Future<ChartData> _chartDataPorEscola;
  late Future<Map<String, double>> _chartDataPorPeriodo; // Receita por período

  // Dados para Gastos e Despesas
  late Future<List<FlSpot>> _chartGastosMensais;
  late Future<Map<String, List<FlSpot>>> _chartGastosCategorias;
  late Future<List<LineChartBarData>> _chartRecebidosGastos;

  bool _isExpanded = false; // Estado da aba "Pagamentos e Mensalidades"
  bool _isExpandedGastos = false; // Estado da aba "Gastos e Despesas"

  @override
  void initState() {
    super.initState();
    // Inicializa os dados para receitas
    _chartData = HomeServiceValoresRecebidos().fetchMonthlyDataForChart();
    _chartDataPorEscola =
        HomeServiceValoresRecebidosPorEscola().fetchMonthlyDataForChart();
    _chartDataPorPeriodo =
        HomeServiceReceitaPorPeriodo().fetchReceitaPorPeriodo();

    // Inicializa os dados para Gastos e Despesas
    _chartGastosMensais = HomeServiceGastosMensais().fetchMonthlyExpenses();
    _chartGastosCategorias =
        HomeServiceGastosMensaisCategorias().fetchMonthlyExpensesByCategory();

    // Inicializa os dados para Recebidos vs Gastos
    _chartRecebidosGastos =
        HomeServiceRecebidosGastos().fetchRecebidosGastosDataForChart();
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
        title: const Text('Dashboard'),
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isWideScreen = constraints.maxWidth > 600;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                // Aba expansível para Pagamentos e Mensalidades (Receitas)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ExpansionTile(
                    title: Text(
                      'Pagamentos e Mensalidades',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: currentTheme.colorScheme.onBackground,
                      ),
                    ),
                    childrenPadding: const EdgeInsets.only(
                      top: 24.0,
                    ), // Espaçamento aumentado
                    initiallyExpanded: _isExpanded,
                    onExpansionChanged: (expanded) {
                      setState(() {
                        _isExpanded = expanded;
                      });
                    },
                    children: [
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        alignment: WrapAlignment.center,
                        children: [
                          ChartCard<List<BarChartGroupData>>(
                            title: 'Receita Mensal',
                            futureData: _chartData,
                            buildChart:
                                (data) => HomeServiceValoresRecebidos()
                                    .buildBarChart(data, context),
                            isWideScreen: isWideScreen,
                            constraints: constraints,
                          ),
                          ChartCard<ChartData>(
                            title: 'Receita por Escola',
                            futureData: _chartDataPorEscola,
                            buildChart:
                                (data) => HomeServiceValoresRecebidosPorEscola()
                                    .buildBarChart(data, context),
                            isWideScreen: isWideScreen,
                            constraints: constraints,
                          ),
                          ChartCard<Map<String, double>>(
                            title: 'Receita por Período',
                            futureData: _chartDataPorPeriodo,
                            buildChart:
                                (data) => HomeServiceReceitaPorPeriodo()
                                    .buildReceitaChart(data, context),
                            isWideScreen: isWideScreen,
                            constraints: constraints,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Aba expansível para Gastos e Despesas
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ExpansionTile(
                    title: Text(
                      'Gastos e Despesas',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: currentTheme.colorScheme.onBackground,
                      ),
                    ),
                    childrenPadding: const EdgeInsets.only(
                      top: 24.0,
                    ), // Espaçamento aumentado
                    initiallyExpanded: _isExpandedGastos,
                    onExpansionChanged: (expanded) {
                      setState(() {
                        _isExpandedGastos = expanded;
                      });
                    },
                    children: [
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        alignment: WrapAlignment.center,
                        children: [
                          ChartCard<List<FlSpot>>(
                            title: 'Despesa Mensal',
                            futureData: _chartGastosMensais,
                            buildChart:
                                (data) => HomeServiceGastosMensais()
                                    .buildLineChart(data, context),
                            isWideScreen: isWideScreen,
                            constraints: constraints,
                          ),
                          ChartCard<List<LineChartBarData>>(
                            title: 'Receita Real',
                            futureData: _chartRecebidosGastos,
                            buildChart:
                                (data) => HomeServiceRecebidosGastos()
                                    .buildLineChart(data, context),
                            isWideScreen: isWideScreen,
                            constraints: constraints,
                            showLegend: true,
                            customLegend: const ReceivedExpensesLegend(),
                          ),
                          ChartCard<Map<String, List<FlSpot>>>(
                            title: 'Despesa por Categoria',
                            futureData: _chartGastosCategorias,
                            buildChart:
                                (data) => HomeServiceGastosMensaisCategorias()
                                    .buildLineChart(data, context),
                            isWideScreen: isWideScreen,
                            constraints: constraints,
                            showLegend: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Widget para exibir cada card de gráfico com animação, placeholder e legenda
class ChartCard<T> extends StatelessWidget {
  final String title;
  final Future<T> futureData;
  final Widget Function(T) buildChart;
  final bool showLegend;
  final Widget? customLegend;
  final bool isWideScreen;
  final BoxConstraints constraints;

  const ChartCard({
    Key? key,
    required this.title,
    required this.futureData,
    required this.buildChart,
    required this.isWideScreen,
    required this.constraints,
    this.showLegend = false,
    this.customLegend,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.titleLarge?.copyWith(
      color: theme.colorScheme.onBackground,
      fontWeight: FontWeight.bold,
    );

    return SizedBox(
      width: isWideScreen ? (constraints.maxWidth / 2) - 16 : double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: textStyle),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: FutureBuilder<T>(
              key: ValueKey(futureData),
              future: futureData,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingPlaceholder(context);
                } else if (snapshot.hasError) {
                  return _buildErrorPlaceholder(
                    context,
                    'Erro ao carregar gráfico',
                  );
                } else if (snapshot.hasData) {
                  final chart = buildChart(snapshot.data!);
                  return Column(
                    key: const ValueKey('chart'),
                    children: [
                      ChartContainer(child: chart),
                      if (showLegend) customLegend ?? const DefaultLegend(),
                    ],
                  );
                } else {
                  return _buildErrorPlaceholder(
                    context,
                    'Nenhum dado disponível',
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingPlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              'Carregando gráfico...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder(BuildContext context, String message) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onError,
          ),
        ),
      ),
    );
  }
}

/// Widget para o container do gráfico com interação
class ChartContainer extends StatelessWidget {
  final Widget child;
  const ChartContainer({Key? key, required this.child}) : super(key: key);

  static const double height = 300;
  static const double width = double.infinity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            spreadRadius: 2,
          ),
        ],
      ),
      child: SizedBox(
        height: height,
        width: width,
        child: GestureDetector(
          onTap: () {
            // Exemplo de interação: mostra detalhes do gráfico
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Detalhes do gráfico')),
            );
          },
          child: child,
        ),
      ),
    );
  }
}

/// Widget para a legenda padrão
class DefaultLegend extends StatelessWidget {
  const DefaultLegend({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final categories = [
      'Mecânico',
      'Peças',
      'Gasolina',
      'Ajudante',
      'Garagem',
      'Outros',
    ];
    final colors = [
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.brown,
      Colors.grey,
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Wrap(
        spacing: 12,
        alignment: WrapAlignment.center,
        children: List.generate(categories.length, (index) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: colors[index],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                categories[index],
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
        }),
      ),
    );
  }
}

/// Widget para a legenda personalizada de "Recebidos vs Gastos"
class ReceivedExpensesLegend extends StatelessWidget {
  const ReceivedExpensesLegend({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final items = [
      {'label': 'Receita Real', 'color': Colors.green},
      {'label': 'Gastos', 'color': Colors.red},
      {'label': 'Receita Total', 'color': Colors.blue},
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children:
            items.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: item['color'] as Color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item['label'] as String,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }
}
