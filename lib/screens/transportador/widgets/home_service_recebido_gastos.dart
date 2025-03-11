import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class HomeServiceRecebidosGastos {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // Função que busca os dados mensais de recebimentos, gastos e diferença
  Future<List<LineChartBarData>> fetchRecebidosGastosDataForChart() async {
    final int currentYear = DateTime.now().year;

    // Verifica se há usuário autenticado
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception("Usuário não autenticado");
    }

    // Referência aos alunos do usuário autenticado
    DatabaseReference userAlunosRef = _database
        .ref()
        .child("users")
        .child(currentUser.uid)
        .child("alunos");

    // Busca os dados no banco de dados de alunos
    DataSnapshot snapshot = await userAlunosRef.get();
    Map<dynamic, dynamic>? alunosData =
        snapshot.value as Map<dynamic, dynamic>?;

    // Referência aos gastos mensais do usuário
    DatabaseReference userGastosRef = _database
        .ref()
        .child("users")
        .child(currentUser.uid)
        .child("gastos");

    // Busca os dados de gastos mensais
    DataSnapshot gastosSnapshot = await userGastosRef.get();
    Map<dynamic, dynamic>? gastosData =
        gastosSnapshot.value as Map<dynamic, dynamic>?;

    // Mapa para armazenar o total recebido e gasto por mês
    Map<int, double> monthlyRecebidos = {for (int i = 1; i <= 12; i++) i: 0.0};
    Map<int, double> monthlyGastos = {for (int i = 1; i <= 12; i++) i: 0.0};

    // Processa os dados de mensalidade dos alunos
    if (alunosData != null) {
      alunosData.forEach((alunoId, alunoData) {
        double valorMensalidade = 0.0;

        if (alunoData["valorMensalidade"] is int) {
          valorMensalidade = (alunoData["valorMensalidade"] as int).toDouble();
        } else if (alunoData["valorMensalidade"] is double) {
          valorMensalidade = alunoData["valorMensalidade"];
        }

        // Obtém os pagamentos
        Map<dynamic, dynamic>? pagamentos =
            alunoData["pagamentos"] as Map<dynamic, dynamic>?;

        if (pagamentos != null) {
          pagamentos.forEach((key, value) {
            List<String> parts = key.toString().split("-");
            if (parts.length >= 2) {
              int? paymentYear = int.tryParse(parts[0]);
              int? paymentMonth = int.tryParse(parts[1]);

              if (paymentYear == currentYear && paymentMonth != null) {
                monthlyRecebidos[paymentMonth] =
                    (monthlyRecebidos[paymentMonth] ?? 0) + valorMensalidade;
              }
            }
          });
        }
      });
    }

    // Processa os dados de gastos
    if (gastosData != null) {
      gastosData.forEach((gastoId, gastoData) {
        double valorGasto = 0.0;

        if (gastoData["value"] is int) {
          valorGasto = (gastoData["value"] as int).toDouble();
        } else if (gastoData["value"] is double) {
          valorGasto = gastoData["value"];
        } else if (gastoData["value"] is String) {
          valorGasto = double.tryParse(gastoData["value"]) ?? 0.0;
        }

        // Obtém o mês e ano do gasto
        var monthData = gastoData["month"];
        var yearData = gastoData["year"];
        int? month =
            monthData is int ? monthData : int.tryParse(monthData.toString());
        int? year =
            yearData is int ? yearData : int.tryParse(yearData.toString());

        // Se o gasto for do ano atual e o mês for válido, soma o valor
        if (year == currentYear && month != null && month >= 1 && month <= 12) {
          monthlyGastos[month] = (monthlyGastos[month] ?? 0) + valorGasto;
        }
      });
    }

    // Cria os pontos do gráfico (FlSpot) para cada mês
    List<LineChartBarData> chartData = [];

    // Linha de recebidos
    chartData.add(
      LineChartBarData(
        spots: List.generate(12, (index) {
          return FlSpot(
            (index + 1).toDouble(),
            monthlyRecebidos[index + 1] ?? 0.0,
          );
        }),
        isCurved: true,
        color: Colors.blue, // Cor para valores recebidos
        barWidth: 2, // Linha mais fina
        isStrokeCapRound: true,
        dotData: FlDotData(show: false), // Remover pontos no gráfico
        belowBarData: BarAreaData(
          show: false,
        ), // Remover sombreado abaixo da linha
      ),
    );

    // Linha de gastos
    chartData.add(
      LineChartBarData(
        spots: List.generate(12, (index) {
          return FlSpot(
            (index + 1).toDouble(),
            monthlyGastos[index + 1] ?? 0.0,
          );
        }),
        isCurved: true,
        color: Colors.red, // Cor para valores gastos
        barWidth: 2, // Linha mais fina
        isStrokeCapRound: true,
        dotData: FlDotData(show: false), // Remover pontos no gráfico
        belowBarData: BarAreaData(
          show: false,
        ), // Remover sombreado abaixo da linha
      ),
    );

    // Linha de diferença (Recebidos - Gastos)
    chartData.add(
      LineChartBarData(
        spots: List.generate(12, (index) {
          double diff =
              (monthlyRecebidos[index + 1] ?? 0.0) -
              (monthlyGastos[index + 1] ?? 0.0);
          return FlSpot((index + 1).toDouble(), diff);
        }),
        isCurved: true,
        color: Colors.green, // Cor para a diferença
        barWidth: 2, // Linha mais fina
        isStrokeCapRound: true,
        dotData: FlDotData(show: false), // Remover pontos no gráfico
        belowBarData: BarAreaData(
          show: false,
        ), // Remover sombreado abaixo da linha
      ),
    );

    return chartData;
  }

  // Função que monta o gráfico de linhas
  Widget buildLineChart(
    List<LineChartBarData> chartData,
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    // Encontra o valor mínimo e máximo do eixo Y
    double globalMaxY = 0.0;
    double globalMinY = 0.0;

    chartData.forEach((barData) {
      for (var spot in barData.spots) {
        if (spot.y > globalMaxY) globalMaxY = spot.y;
        if (spot.y < globalMinY) globalMinY = spot.y;
      }
    });

    // Ajusta o eixo Y para que a linha verde (negativa) seja visível
    globalMinY = globalMinY < 0 ? globalMinY * 1.2 : 0;
    globalMaxY = globalMaxY * 1.2;

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false), // Remover o grid
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            axisNameSize: 16,
            axisNameWidget: Container(),
            sideTitles: SideTitles(
              showTitles: true,
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
                return Text(
                  months[value.toInt() - 1],
                  style: TextStyle(fontSize: 10), // Títulos mais simples
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            axisNameSize: 16,
            axisNameWidget: Container(),
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(fontSize: 10), // Títulos mais simples
                );
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false), // Sem bordas
        minX: 1,
        maxX: 12,
        minY: globalMinY,
        maxY: globalMaxY,
        lineBarsData: chartData,
      ),
    );
  }
}
