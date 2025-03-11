import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class HomeServiceGastosMensaisCategorias {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // Busca os gastos do ano atual, agrupados por categoria e por mês
  Future<Map<String, List<FlSpot>>> fetchMonthlyExpensesByCategory() async {
    final int currentYear = DateTime.now().year;

    // Verifica se há usuário autenticado
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception("Usuário não autenticado");
    }

    // Referência aos gastos do usuário
    DatabaseReference gastosRef = _database
        .ref()
        .child("users")
        .child(currentUser.uid)
        .child("gastos");

    DataSnapshot snapshot = await gastosRef.get();
    Map<dynamic, dynamic>? gastosData =
        snapshot.value as Map<dynamic, dynamic>?;

    // Mapa para agrupar os gastos por categoria e mês
    // Para cada categoria, teremos um mapa de mês (1 a 12) para total gasto
    Map<String, Map<int, double>> categoryTotals = {};

    if (gastosData != null) {
      gastosData.forEach((key, gastoData) {
        var monthData = gastoData["month"];
        var yearData = gastoData["year"];
        int? month =
            monthData is int ? monthData : int.tryParse(monthData.toString());
        int? year =
            yearData is int ? yearData : int.tryParse(yearData.toString());

        // Considera apenas os registros do ano atual e meses válidos
        if (year != currentYear || month == null || month < 1 || month > 12) {
          return;
        }

        // Obtém a categoria; se não estiver definida, usa "Desconhecido"
        String category = gastoData["category"] ?? "Desconhecido";

        // Converte o valor para double
        double value = 0.0;
        var valor = gastoData["value"];
        if (valor is int) {
          value = valor.toDouble();
        } else if (valor is double) {
          value = valor;
        } else if (valor is String) {
          value = double.tryParse(valor) ?? 0.0;
        }

        // Inicializa o mapa para a categoria, se necessário
        if (!categoryTotals.containsKey(category)) {
          categoryTotals[category] = {for (int i = 1; i <= 12; i++) i: 0.0};
        }
        // Soma o valor do gasto no mês correspondente para a categoria
        categoryTotals[category]![month] =
            (categoryTotals[category]![month] ?? 0) + value;
      });
    }

    // Converte os totais mensais de cada categoria para uma lista de FlSpot
    Map<String, List<FlSpot>> categorySpots = {};
    categoryTotals.forEach((category, monthlyMap) {
      List<FlSpot> spots = [];
      for (int month = 1; month <= 12; month++) {
        spots.add(FlSpot(month.toDouble(), monthlyMap[month] ?? 0));
      }
      categorySpots[category] = spots;
    });

    return categorySpots;
  }

  // Constrói o gráfico de linha com uma linha para cada categoria
  Widget buildLineChart(Map<String, List<FlSpot>> data, BuildContext context) {
    final theme = Theme.of(context);

    // Lista de cores para as linhas; se houver mais categorias, as cores serão recicladas
    final List<Color> lineColors = [
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.brown,
      Colors.grey,
      Colors.red,
    ];

    // Calcula o valor máximo do eixo Y considerando todos os pontos
    double globalMaxY = 0.0;
    data.forEach((_, spots) {
      for (var spot in spots) {
        if (spot.y > globalMaxY) globalMaxY = spot.y;
      }
    });
    globalMaxY = globalMaxY == 0 ? 100.0 : globalMaxY * 1.2;

    // Cria uma lista de linhas (uma para cada categoria)
    List<LineChartBarData> lineBars = [];
    int colorIndex = 0;
    data.forEach((category, spots) {
      final color = lineColors[colorIndex % lineColors.length];
      colorIndex++;
      lineBars.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          barWidth: 2,
          color: color,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
      );
    });

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (double value, TitleMeta meta) {
                final months = [
                  'Jan',
                  'Feb',
                  'Mar',
                  'Apr',
                  'May',
                  'Jun',
                  'Jul',
                  'Aug',
                  'Sep',
                  'Oct',
                  'Nov',
                  'Dec',
                ];
                int index = value.toInt() - 1;
                return Text(
                  (index >= 0 && index < months.length) ? months[index] : '',
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: globalMaxY / 5,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                );
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 1,
        maxX: 12,
        minY: 0,
        maxY: globalMaxY,
        lineBarsData: lineBars,
      ),
    );
  }
}
