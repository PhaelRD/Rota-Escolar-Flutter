import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class HomeServiceValoresRecebidos {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  Future<List<BarChartGroupData>> fetchMonthlyDataForChart() async {
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

    // Busca os dados no banco
    DataSnapshot snapshot = await userAlunosRef.get();
    Map<dynamic, dynamic>? alunosData =
        snapshot.value as Map<dynamic, dynamic>?;

    // Mapa para armazenar o total recebido por mês no ano atual
    Map<int, double> monthlyTotals = {for (int i = 1; i <= 12; i++) i: 0.0};

    if (alunosData != null) {
      alunosData.forEach((alunoId, alunoData) {
        double valorMensalidade = 0.0;

        if (alunoData["valorMensalidade"] is int) {
          valorMensalidade = (alunoData["valorMensalidade"] as int).toDouble();
        } else if (alunoData["valorMensalidade"] is double) {
          valorMensalidade = alunoData["valorMensalidade"];
        }

        // Obtém os pagamentos e filtra pelo ano atual
        Map<dynamic, dynamic>? pagamentos =
            alunoData["pagamentos"] as Map<dynamic, dynamic>?;

        if (pagamentos != null) {
          pagamentos.forEach((key, value) {
            List<String> parts = key.toString().split("-");
            if (parts.length >= 2) {
              int? paymentYear = int.tryParse(parts[0]);
              int? paymentMonth = int.tryParse(parts[1]);

              if (paymentYear == currentYear && paymentMonth != null) {
                monthlyTotals[paymentMonth] =
                    (monthlyTotals[paymentMonth] ?? 0) + valorMensalidade;
              }
            }
          });
        }
      });
    }

    // Prepara os dados para o fl_chart
    List<BarChartGroupData> barChartData =
        monthlyTotals.entries.where((entry) => entry.value > 0).map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value,
            width: 16,
            color: Colors.yellow, // Cor da barra
          ),
        ],
      );
    }).toList();

    return barChartData;
  }

  // Função que monta o gráfico de barras
  Widget buildBarChart(List<BarChartGroupData> chartData, BuildContext context) {
    final themeProvider = Theme.of(context); // Obtém o tema atual

    return BarChart(
      BarChartData(
        gridData: FlGridData(show: false), // Desativa a grade
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            axisNameSize: 16,
            axisNameWidget: Container(),
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                final months = [
                  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                ];
                // Exibe apenas os meses com valores
                return Text(
                  months[value.toInt() - 1],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: themeProvider.colorScheme.onSurface.withOpacity(0.7),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            axisNameSize: 16,
            axisNameWidget: Container(),
            sideTitles: SideTitles(
              showTitles: true,
              interval: 100, // Aumenta o intervalo dos números no eixo Y
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    fontSize: 10,
                    color: themeProvider.colorScheme.onSurface.withOpacity(0.7),
                  ),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false), // Desabilita os números à direita
          ),
        ),
        borderData: FlBorderData(show: false), // Remove a borda do gráfico
        barGroups: chartData,
      ),
    );
  }
}
