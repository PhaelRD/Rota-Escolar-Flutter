import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class HomeServiceGastosMensais {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // Função para buscar os gastos mensais do ano atual e retornar uma lista de FlSpot
  Future<List<FlSpot>> fetchMonthlyExpenses() async {
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

    // Inicializa um mapa para armazenar o total de gastos de cada mês (1 a 12)
    Map<int, double> monthlyTotals = {for (int i = 1; i <= 12; i++) i: 0.0};

    if (gastosData != null) {
      gastosData.forEach((key, gastoData) {
        // Obtém os valores de mês, ano e valor do gasto
        var monthData = gastoData["month"];
        var yearData = gastoData["year"];
        int? month =
            monthData is int ? monthData : int.tryParse(monthData.toString());
        int? year =
            yearData is int ? yearData : int.tryParse(yearData.toString());
        double value = 0.0;
        var valor = gastoData["value"];
        if (valor is int) {
          value = valor.toDouble();
        } else if (valor is double) {
          value = valor;
        } else if (valor is String) {
          value = double.tryParse(valor) ?? 0.0;
        }

        // Se o gasto for do ano atual e o mês for válido, soma o valor
        if (year == currentYear && month != null && month >= 1 && month <= 12) {
          monthlyTotals[month] = (monthlyTotals[month] ?? 0) + value;
        }
      });
    }

    // Cria os pontos do gráfico (FlSpot) para cada mês (mesmo que o valor seja zero)
    List<FlSpot> spots = [];
    for (int month = 1; month <= 12; month++) {
      spots.add(FlSpot(month.toDouble(), monthlyTotals[month]!));
    }

    return spots;
  }

  // Função que constrói o gráfico de linha com base nos dados (spots)
  Widget buildLineChart(List<FlSpot> spots, BuildContext context) {
    final theme = Theme.of(context);

    // Calcula o máximo do eixo Y com margem
    double maxY = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    maxY = maxY == 0 ? 100.0 : maxY * 1.2;

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false), // Remove as linhas da grade
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
              interval: maxY / 5,
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
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 2,
            color: Colors.red,
            dotData: FlDotData(
              show: false,
            ), // Remove os pontos para uma linha mais limpa
            belowBarData: BarAreaData(
              show: false,
            ), // Remove o sombreado abaixo da linha
          ),
        ],
      ),
    );
  }
}
