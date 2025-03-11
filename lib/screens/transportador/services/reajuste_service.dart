import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;

class ReajusteService {
  // Referência para o nó raiz do Realtime Database
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();

  // Configurações da API do Brevo
  final String _brevoApiKey =
      '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'; // Substitua pela sua API Key
  final String _brevoBaseUrl = 'https://api.brevo.com/v3';

  /// Função para obter a lista de alunos cadastrados para um determinado usuário.
  Future<List<Map<String, dynamic>>> getAlunos(String userId) async {
    List<Map<String, dynamic>> alunos = [];
    try {
      final DatabaseEvent event =
          await _databaseRef.child('users/$userId/alunos').once();
      final DataSnapshot snapshot = event.snapshot;

      if (snapshot.value != null) {
        final alunosMap = Map<String, dynamic>.from(snapshot.value as Map);
        alunosMap.forEach((alunoId, alunoData) {
          final data = Map<String, dynamic>.from(alunoData);
          alunos.add({
            'alunoId': alunoId,
            'nomeAluno': data['nomeAluno'] ?? '',
            'valorMensalidade': data['valorMensalidade'] ?? 0,
          });
        });
      }
    } catch (e) {
      print('Erro ao recuperar alunos: $e');
    }
    return alunos;
  }

  /// Função para aplicar um reajuste percentual no valor da mensalidade de alunos selecionados.
  Future<void> aplicarReajuste(
      String userId, List<String> alunoIds, double reajustePercent) async {
    final double fator = 1 + (reajustePercent / 100);

    for (final alunoId in alunoIds) {
      try {
        final DatabaseReference alunoRef =
            _databaseRef.child('users/$userId/alunos/$alunoId');

        final DatabaseEvent event =
            await alunoRef.child('valorMensalidade').once();
        final DataSnapshot snapshot = event.snapshot;

        if (snapshot.value != null) {
          double valorAtual;
          if (snapshot.value is int) {
            valorAtual = (snapshot.value as int).toDouble();
          } else if (snapshot.value is double) {
            valorAtual = snapshot.value as double;
          } else {
            valorAtual = double.tryParse(snapshot.value.toString()) ?? 0;
          }

          final double novoValor = valorAtual * fator;
          final double novoValorFormatado =
              double.parse(novoValor.toStringAsFixed(2));

          await alunoRef.update({'valorMensalidade': novoValorFormatado});
        }
      } catch (e) {
        print('Erro ao aplicar reajuste para o aluno $alunoId: $e');
      }
    }
  }

  /// Função para pesquisar alunos por nome ou valor da mensalidade.
  Future<List<Map<String, dynamic>>> searchAlunos(
    String userId, {
    String? nomePesquisa,
    double? valorMensalidade,
  }) async {
    List<Map<String, dynamic>> alunos = await getAlunos(userId);

    if (nomePesquisa != null && nomePesquisa.isNotEmpty) {
      alunos = alunos.where((aluno) {
        final nome = aluno['nomeAluno'].toString().toLowerCase();
        return nome.contains(nomePesquisa.toLowerCase());
      }).toList();
    }

    if (valorMensalidade != null) {
      alunos = alunos.where((aluno) {
        final valor = aluno['valorMensalidade'];
        return valor == valorMensalidade;
      }).toList();
    }

    return alunos;
  }

  /// Função para obter todos os IDs dos alunos cadastrados para um determinado usuário.
  Future<List<String>> getAllAlunosIds(String userId) async {
    List<Map<String, dynamic>> alunos = await getAlunos(userId);
    return alunos.map((aluno) => aluno['alunoId'].toString()).toList();
  }

  /// Função para verificar o plano do usuário.
  Future<String?> getUserPlan(String userId) async {
    try {
      final DatabaseEvent event =
          await _databaseRef.child('users/$userId/userInfos/plano').once();
      final DataSnapshot snapshot = event.snapshot;
      if (snapshot.value != null) {
        return snapshot.value.toString();
      }
    } catch (e) {
      print('Erro ao recuperar o plano do usuário: $e');
    }
    return null;
  }

  // --- Funções auxiliares para integração com a API do Brevo ---

  /// Verifica se o contato já existe no Brevo. Se não existir, adiciona-o.
  Future<void> _adicionarContatoSeNecessario(String email) async {
    final String contactUrl =
        '$_brevoBaseUrl/contacts/${Uri.encodeComponent(email)}';
    try {
      final response = await http.get(
        Uri.parse(contactUrl),
        headers: {
          'api-key': _brevoApiKey,
          'Content-Type': 'application/json',
        },
      );

      // Se o contato não existir (status 404), adiciona-o.
      if (response.statusCode == 404) {
        final String createContactUrl = '$_brevoBaseUrl/contacts';
        final createResponse = await http.post(
          Uri.parse(createContactUrl),
          headers: {
            'api-key': _brevoApiKey,
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'email': email}),
        );
        if (createResponse.statusCode != 201 &&
            createResponse.statusCode != 200) {
          print(
              'Erro ao adicionar contato $email no Brevo: ${createResponse.body}');
        }
      }
    } catch (e) {
      print('Erro na verificação/adicionar contato para $email: $e');
    }
  }

  /// Envia um e-mail de notificação de reajuste para o responsável.
  /// O e-mail inclui:
  /// - Nome do aluno reajustado
  /// - Novo valor da mensalidade
  /// - Nome da empresa
  Future<void> _enviarEmailReajuste(String email, double reajustePercent,
      String nomeAluno, String novoValor, String companyName) async {
    final String sendEmailUrl = '$_brevoBaseUrl/smtp/email';

    final Map<String, dynamic> payload = {
      'sender': {
        'name': companyName, // Nome da empresa
        'email': 'raphaelr2014@gmail.com' // E-mail do remetente
      },
      'to': [
        {'email': email}
      ],
      'subject': 'Aviso de reajuste de mensalidade',
      'htmlContent': '<html>'
          '<body>'
          '<p>Prezado(a),</p>'
          '<p>Informamos que o aluno <strong>$nomeAluno</strong> teve um reajuste em sua mensalidade.</p>'
          '<p><strong>Novo valor da mensalidade:</strong> R\$ $novoValor</p>'
          '<p><strong>Empresa:</strong> $companyName</p>'
          '<p><strong>Reajuste aplicado:</strong> ${reajustePercent.toStringAsFixed(2)}%</p>'
          '<p>Atenciosamente,<br>$companyName</p>'
          '</body>'
          '</html>',
    };

    try {
      final response = await http.post(
        Uri.parse(sendEmailUrl),
        headers: {
          'api-key': _brevoApiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );
      if (response.statusCode != 201 && response.statusCode != 200) {
        print('Erro ao enviar email para $email: ${response.body}');
      }
    } catch (e) {
      print('Erro ao enviar email para $email: $e');
    }
  }

  /// Função para notificar os responsáveis dos alunos que tiveram reajuste.
  ///
  /// Para cada aluno, são recuperados:
  /// - O e-mail do responsável (campo `emailResponsavel`)
  /// - O nome do aluno (campo `nomeAluno`)
  /// - O novo valor da mensalidade (campo `valorMensalidade`)
  /// Além disso, é buscado o nome da empresa em `users/[userId]/userInfos/username`.
  Future<void> notificarResponsaveisReajuste(
      String userId, List<String> alunoIds, double reajustePercent) async {
    // Obtém o nome da empresa a partir do campo `username`
    String companyName = '';
    try {
      final DatabaseReference userInfosRef =
          _databaseRef.child('users/$userId/userInfos/username');
      final DatabaseEvent userEvent = await userInfosRef.once();
      final DataSnapshot userSnapshot = userEvent.snapshot;
      if (userSnapshot.value != null) {
        companyName = userSnapshot.value.toString();
      }
    } catch (e) {
      print('Erro ao recuperar o nome da empresa: $e');
    }

    for (final alunoId in alunoIds) {
      try {
        // Recupera os dados completos do aluno
        final DatabaseReference alunoRef =
            _databaseRef.child('users/$userId/alunos/$alunoId');
        final DatabaseEvent event = await alunoRef.once();
        final DataSnapshot snapshot = event.snapshot;

        if (snapshot.value != null && snapshot.value is Map) {
          final Map<String, dynamic> alunoData =
              Map<String, dynamic>.from(snapshot.value as Map);
          final String email = alunoData['emailResponsavel']?.toString() ?? '';
          final String nomeAluno = alunoData['nomeAluno']?.toString() ?? '';
          final String novoValor =
              alunoData['valorMensalidade']?.toString() ?? '';

          if (email.isNotEmpty) {
            // Adiciona o contato no Brevo se necessário.
            await _adicionarContatoSeNecessario(email);

            // Envia o e-mail de notificação com os dados atualizados.
            await _enviarEmailReajuste(
                email, reajustePercent, nomeAluno, novoValor, companyName);
          } else {
            print('Email não encontrado para o aluno $alunoId.');
          }
        }
      } catch (e) {
        print('Erro ao notificar responsável do aluno $alunoId: $e');
      }
    }
  }
}
