import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class HomeServiceReceitaPorPeriodo {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  Future<Map<String, double>> fetchReceitaPorPeriodo() async {
    final int currentYear = DateTime.now().year;
    final int currentMonth = DateTime.now().month;

    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception("Usuário não autenticado");
    }

    DatabaseReference userAlunosRef = _database
        .ref()
        .child("users")
        .child(currentUser.uid)
        .child("alunos");

    DataSnapshot snapshotAlunos = await userAlunosRef.get();
    Map<dynamic, dynamic>? alunosData =
        snapshotAlunos.value as Map<dynamic, dynamic>?;

    Map<String, double> receitaPorPeriodo = {};

    if (alunosData != null) {
      alunosData.forEach((alunoId, alunoData) {
        String periodo = alunoData["periodo"] ?? "Desconhecido";
        double valorMensalidade =
            (alunoData["valorMensalidade"] ?? 0.0).toDouble();

        Map<dynamic, dynamic>? pagamentos =
            alunoData["pagamentos"] as Map<dynamic, dynamic>?;

        if (pagamentos != null) {
          pagamentos.forEach((key, value) {
            List<String> parts = key.toString().split("-");
            if (parts.length >= 2) {
              int? paymentYear = int.tryParse(parts[0]);
              int? paymentMonth = int.tryParse(parts[1]);

              if (paymentYear == currentYear && paymentMonth == currentMonth) {
                receitaPorPeriodo.update(
                  periodo,
                  (existing) => existing + valorMensalidade,
                  ifAbsent: () => valorMensalidade,
                );
              }
            }
          });
        }
      });
    }

    return receitaPorPeriodo;
  }

  Widget buildReceitaChart(
    Map<String, double> receitaPorPeriodo,
    BuildContext context,
  ) {
    final themeProvider = Theme.of(context);
    double maxY =
        receitaPorPeriodo.isNotEmpty
            ? receitaPorPeriodo.values.reduce((a, b) => a > b ? a : b)
            : 100;

    return AspectRatio(
      aspectRatio: 1.5, // Ajusta automaticamente o tamanho
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceEvenly,
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              axisNameWidget: Container(),
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  String periodo = receitaPorPeriodo.keys.elementAt(
                    value.toInt(),
                  );
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      periodo,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                        color: themeProvider.colorScheme.onSurface.withOpacity(
                          0.7,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: maxY / 5,
                getTitlesWidget: (double value, TitleMeta meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      fontSize: 10,
                      color: themeProvider.colorScheme.onSurface.withOpacity(
                        0.7,
                      ),
                    ),
                  );
                },
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups:
              receitaPorPeriodo.entries.map((entry) {
                int index = receitaPorPeriodo.keys.toList().indexOf(entry.key);
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value,
                      width: 16,
                      color: Colors.yellow,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                );
              }).toList(),
          maxY: maxY + 20,
        ),
      ),
    );
  }
}
