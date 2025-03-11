import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AvisosService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  /// Busca todos os alunos do usuário autenticado
  Future<List<Map<String, dynamic>>> getAllAlunos() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('Usuário não autenticado');
    }
    DatabaseEvent event =
        await _dbRef
            .child('users')
            .child(currentUser.uid)
            .child('alunos')
            .once();

    List<Map<String, dynamic>> alunosList = [];
    if (event.snapshot.value != null) {
      Map<dynamic, dynamic> alunosMap = event.snapshot.value as Map;
      alunosMap.forEach((key, value) {
        alunosList.add(Map<String, dynamic>.from(value)..['id'] = key);
      });
    }
    return alunosList;
  }

  /// Verifica o status dos alunos para um mês e ano específicos.
  /// Apenas alunos cujo campo 'dataRegistro' seja anterior ou igual
  /// ao período selecionado (ano/mês) serão incluídos na lista.
  Future<List<Map<String, dynamic>>> verificarStatusAlunos(
    int ano,
    int mes,
  ) async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('Usuário não autenticado');
    }

    List<Map<String, dynamic>> alunos = await getAllAlunos();
    List<Map<String, dynamic>> alunosFiltrados = [];

    DateTime now = DateTime.now();
    int currentYear = now.year;
    int currentMonth = now.month;
    int currentDay = now.day;
    String periodo = "$ano-$mes"; // Formato "YYYY-MM"

    for (var aluno in alunos) {
      // Filtra alunos com base na data de registro
      String? dataRegistroStr = aluno['dataRegistro']?.toString();
      if (dataRegistroStr != null && dataRegistroStr.isNotEmpty) {
        List<String> regParts = dataRegistroStr.split('-');
        if (regParts.length == 2) {
          int regYear = int.tryParse(regParts[0]) ?? 0;
          int regMonth = int.tryParse(regParts[1]) ?? 0;
          DateTime regDate = DateTime(regYear, regMonth);
          DateTime selectedDate = DateTime(ano, mes);
          // Se o período selecionado for anterior à data de registro, pula esse aluno
          if (selectedDate.isBefore(regDate)) {
            continue;
          }
        }
      }

      // Calcula o status do aluno
      String alunoId = aluno['id'];
      int? dueDay = int.tryParse(aluno['dataVencimento']?.toString() ?? '');
      String status;

      // Primeiro, verifica se o pagamento já foi feito para aquele mês/ano
      DatabaseEvent pagamentoEvent =
          await _dbRef
              .child('users')
              .child(currentUser.uid)
              .child('alunos')
              .child(alunoId)
              .child('pagamentos')
              .child(periodo)
              .once();

      bool pago = pagamentoEvent.snapshot.value != null;

      if (pago) {
        status = "pago";
      } else {
        // Se não foi pago, verifica a situação com base na data
        DateTime selectedDate = DateTime(ano, mes);

        if (selectedDate.isAfter(DateTime(currentYear, currentMonth))) {
          // Se for um mês futuro e não estiver pago, define como "pendente"
          status = "pendente";
        } else if (ano < currentYear ||
            (ano == currentYear && mes < currentMonth)) {
          // Se for um mês/ano anterior e não estiver pago, é "atrasado"
          status = "atrasado";
        } else if (dueDay == null || dueDay <= 0) {
          status = "data inválida";
        } else if (DateTime(
          ano,
          mes,
          currentDay,
        ).isAfter(DateTime(ano, mes, dueDay))) {
          // Se a data atual for depois da data de vencimento, mesmo que seja o mês corrente, é "atrasado"
          status = "atrasado";
        } else {
          status = "pendente";
        }
      }

      aluno['status'] = status;
      alunosFiltrados.add(aluno);
    }
    return alunosFiltrados;
  }

  /// Salva o pagamento do aluno no nó `users/[userId]/alunos/[alunoId]/pagamentos`
  Future<void> salvarPagamento(String alunoId, int ano, int mes) async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('Usuário não autenticado');
    }
    String periodo = "$ano-$mes"; // Formato "YYYY-MM"
    DatabaseReference pagamentoRef = _dbRef
        .child('users')
        .child(currentUser.uid)
        .child('alunos')
        .child(alunoId)
        .child('pagamentos')
        .child(periodo);

    // Salva como "pago"
    await pagamentoRef.set("pago");
  }

  /// Função para enviar cobrança por WhatsApp
  /// Recebe o mês selecionado na tela para compor a data (dataVencimento/mesSelecionado)
  Future<void> enviarCobranca(
    BuildContext context,
    String alunoId,
    int selectedMonth,
  ) async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('Usuário não autenticado');
    }

    // Verifica se o campo PIX está cadastrado e obtém seu valor
    DatabaseEvent pixEvent =
        await _dbRef
            .child('users')
            .child(currentUser.uid)
            .child('userInfos')
            .child('pix')
            .once();

    if (pixEvent.snapshot.value == null) {
      // Exibe alerta informando que o Pix não está cadastrado
      await showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('Aviso'),
              content: Text(
                'Pix não está cadastrado. Por favor, cadastre-o no perfil.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('OK'),
                ),
              ],
            ),
      );
      return;
    }
    String pixValue = pixEvent.snapshot.value.toString();

    // Recupera os dados do aluno
    DatabaseEvent alunoEvent =
        await _dbRef
            .child('users')
            .child(currentUser.uid)
            .child('alunos')
            .child(alunoId)
            .once();

    if (alunoEvent.snapshot.value == null) {
      throw Exception('Aluno não encontrado');
    }
    Map<String, dynamic> alunoData = Map<String, dynamic>.from(
      alunoEvent.snapshot.value as Map,
    );

    // Extrai informações necessárias do aluno
    String? telefone1 = alunoData['telefone1']?.toString();
    String? telefone2 = alunoData['telefone2']?.toString();
    String dataVencimento = alunoData['dataVencimento']?.toString() ?? '';
    String nomeAluno = alunoData['nomeAluno']?.toString() ?? '';
    String nomeResponsavel = alunoData['nomeResponsavel']?.toString() ?? '';
    String valorMensalidade = alunoData['valorMensalidade']?.toString() ?? '';

    // Recupera o username do usuário
    DatabaseEvent usernameEvent =
        await _dbRef
            .child('users')
            .child(currentUser.uid)
            .child('userInfos')
            .child('username')
            .once();

    String username = usernameEvent.snapshot.value?.toString() ?? '';

    // Abre uma janela flutuante para escolher o telefone (se houver mais de um)
    String? selectedTelefone = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Escolha o telefone'),
          content: Text('Selecione o telefone para enviar a cobrança'),
          actions: [
            if (telefone1 != null && telefone1.isNotEmpty)
              TextButton(
                onPressed: () => Navigator.of(context).pop(telefone1),
                child: Text('Telefone 1: $telefone1'),
              ),
            if (telefone2 != null && telefone2.isNotEmpty)
              TextButton(
                onPressed: () => Navigator.of(context).pop(telefone2),
                child: Text('Telefone 2: $telefone2'),
              ),
          ],
        );
      },
    );

    if (selectedTelefone == null) return; // Caso o usuário não escolha

    // Compoe a mensagem de cobrança incluindo o valor Pix e o pedido para enviar o comprovante.
    // A data de vencimento será exibida no formato "dataVencimento/selectedMonth"
    String message =
        "Olá $nomeResponsavel, aqui é $username. "
        "Lembrete: a mensalidade do transporte escolar de $nomeAluno com vencimento em $dataVencimento/$selectedMonth está pendente. "
        "Valor: $valorMensalidade. Valor Pix: $pixValue. "
        "Por favor, efetue o pagamento via Pix e envie o comprovante.";

    // Monta a URL para enviar a mensagem via WhatsApp
    final whatsappUrl =
        "https://wa.me/$selectedTelefone?text=${Uri.encodeComponent(message)}";
    if (await canLaunch(whatsappUrl)) {
      await launch(whatsappUrl);
    } else {
      throw Exception('Não foi possível abrir o WhatsApp');
    }
  }
}
