import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class AlunosService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  Future<int> verificarLimiteAlunos() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('Usuário não autenticado.');
    }

    try {
      // Caminho no Realtime Database
      final userId = currentUser.uid;
      final userInfosRef = _database.ref('users/$userId/userInfos/plano');

      // Obter valor do plano
      final snapshot = await userInfosRef.get();
      if (!snapshot.exists) {
        throw Exception('Plano não encontrado para o usuário.');
      }

      // Converter o valor para um inteiro
      final plano = int.tryParse(snapshot.value.toString()) ?? -1;

      // Determinar o limite de alunos
      if (plano == 0) {
        return 15;
      } else if (plano == 1) {
        return 150;
      } else {
        throw Exception('Plano desconhecido.');
      }
    } catch (e) {
      throw Exception('Erro ao obter o plano do usuário: $e');
    }
  }

  /// Verifica a quantidade de alunos registrados no Realtime Database
  Future<int> contarAlunosRegistrados() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('Usuário não autenticado.');
    }

    try {
      // Caminho no Realtime Database
      final userId = currentUser.uid;
      final alunosRef = _database.ref('users/$userId/alunos');

      // Obter os dados dos alunos
      final snapshot = await alunosRef.get();
      if (!snapshot.exists) {
        return 0; // Nenhum aluno registrado
      }

      // Contar o número de alunos registrados
      final alunosMap = snapshot.value as Map<dynamic, dynamic>;
      return alunosMap.length;
    } catch (e) {
      throw Exception('Erro ao contar alunos registrados: $e');
    }
  }

  /// Busca as escolas registradas no Firebase
  Future<Map<String, String>> buscarEscolas() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('Usuário não autenticado.');
    }

    try {
      // Caminho no Realtime Database
      final userId = currentUser.uid;
      final escolasRef = _database.ref('users/$userId/escolas');

      // Obter os dados das escolas
      final snapshot = await escolasRef.get();
      if (!snapshot.exists) {
        return {}; // Retorna vazio se não houver escolas
      }

      final escolasMap = snapshot.value as Map<dynamic, dynamic>;

      // Retorna um mapa de {idEscola: nomeEscola}
      return escolasMap.map(
        (key, value) => MapEntry(key.toString(), value['nome'].toString()),
      );
    } catch (e) {
      throw Exception('Erro ao buscar escolas: $e');
    }
  }

  /// Registra um aluno no Realtime Database, salvando também a data de registro no formato "ano-mês" (exemplo: "2025-02")
  Future<void> registrarAluno({
    required String idEscola,
    required String nomeAluno,
    required int idadeAluno,
    required double valorMensalidade,
    required String dataVencimento,
    required String periodo,
    required String nomeResponsavel,
    required String telefone1,
    String? telefone2,
    String? emailResponsavel,
    required String enderecoRetirada,
    required String enderecoEntrega,
  }) async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('Usuário não autenticado.');
    }

    try {
      // Verificar o limite de alunos
      final maxAlunos = await verificarLimiteAlunos();
      final alunosRegistrados = await contarAlunosRegistrados();

      if (alunosRegistrados >= maxAlunos) {
        throw Exception('Limite de alunos registrado alcançado.');
      }

      // Caminho no Realtime Database
      final userId = currentUser.uid;
      final alunosRef = _database.ref('users/$userId/alunos');

      // Criar um ID único para o aluno
      final alunoId = alunosRef.push().key;

      if (alunoId == null) {
        throw Exception('Erro ao gerar ID do aluno.');
      }

      // Gerar a data de registro automaticamente no formato "ano-mês"
      final now = DateTime.now();
      final dataRegistro =
          "${now.year}-${now.month.toString().padLeft(2, '0')}";

      // Dados do aluno, incluindo a data de registro
      final alunoData = {
        'idEscola': idEscola,
        'nomeAluno': nomeAluno,
        'idadeAluno': idadeAluno,
        'valorMensalidade': valorMensalidade,
        'dataVencimento': dataVencimento,
        'periodo': periodo,
        'nomeResponsavel': nomeResponsavel,
        'telefone1': telefone1,
        'telefone2': telefone2 ?? '',
        'emailResponsavel': emailResponsavel ?? '',
        'enderecoRetirada': enderecoRetirada,
        'enderecoEntrega': enderecoEntrega,
        'dataRegistro': dataRegistro,
      };

      // Salvar no Firebase
      await alunosRef.child(alunoId).set(alunoData);
    } catch (e) {
      throw Exception('Erro ao registrar aluno: $e');
    }
  }

  /// Lista todos os alunos registrados e adiciona o nome da escola
  Future<List<Map<String, dynamic>>> listarAlunos() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('Usuário não autenticado.');
    }

    try {
      // Caminho no Realtime Database
      final userId = currentUser.uid;
      final alunosRef = _database.ref('users/$userId/alunos');
      final escolasRef = _database.ref('users/$userId/escolas');

      // Obter os dados dos alunos
      final alunosSnapshot = await alunosRef.get();
      if (!alunosSnapshot.exists) {
        return []; // Retorna uma lista vazia se não houver alunos
      }

      // Obter os dados das escolas
      final escolasSnapshot = await escolasRef.get();
      final escolasMap =
          escolasSnapshot.exists
              ? escolasSnapshot.value as Map<dynamic, dynamic>
              : {};

      // Converte os dados dos alunos em uma lista de mapas
      final alunosMap = alunosSnapshot.value as Map<dynamic, dynamic>;
      return alunosMap.entries.map((entry) {
        final alunoData = entry.value as Map<dynamic, dynamic>;
        final idEscola = alunoData['idEscola']?.toString();

        // Obter o nome da escola correspondente
        final nomeEscola =
            idEscola != null && escolasMap.containsKey(idEscola)
                ? escolasMap[idEscola]['nome'].toString()
                : 'Escola não encontrada';

        return {
          'id': entry.key,
          'nomeEscola': nomeEscola,
          ...alunoData.map((key, value) => MapEntry(key.toString(), value)),
        };
      }).toList();
    } catch (e) {
      throw Exception('Erro ao listar alunos: $e');
    }
  }

  /// Edita as informações de um aluno existente
  Future<void> editarAluno({
    required String alunoId,
    required String idEscola,
    required String nomeAluno,
    required int idadeAluno,
    required double valorMensalidade,
    required String dataVencimento,
    required String periodo,
    required String nomeResponsavel,
    required String telefone1,
    String? telefone2,
    String? emailResponsavel,
    required String enderecoRetirada,
    required String enderecoEntrega,
  }) async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('Usuário não autenticado.');
    }

    try {
      // Caminho no Realtime Database
      final userId = currentUser.uid;
      final alunoRef = _database.ref('users/$userId/alunos/$alunoId');

      // Dados atualizados do aluno
      final alunoData = {
        'idEscola': idEscola,
        'nomeAluno': nomeAluno,
        'idadeAluno': idadeAluno,
        'valorMensalidade': valorMensalidade,
        'dataVencimento': dataVencimento,
        'periodo': periodo,
        'nomeResponsavel': nomeResponsavel,
        'telefone1': telefone1,
        'telefone2': telefone2 ?? '',
        'emailResponsavel': emailResponsavel ?? '',
        'enderecoRetirada': enderecoRetirada,
        'enderecoEntrega': enderecoEntrega,
      };

      // Atualizar os dados no Firebase
      await alunoRef.update(alunoData);
    } catch (e) {
      throw Exception('Erro ao editar aluno: $e');
    }
  }

  /// Exclui um aluno do Realtime Database
  Future<void> excluirAluno(String alunoId) async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('Usuário não autenticado.');
    }

    try {
      // Caminho no Realtime Database
      final userId = currentUser.uid;
      final alunoRef = _database.ref('users/$userId/alunos/$alunoId');

      // Remover o aluno
      await alunoRef.remove();
    } catch (e) {
      throw Exception('Erro ao excluir aluno: $e');
    }
  }

  /// Função para pesquisar escolas pelo nome
  Future<List<Map<String, dynamic>>> pesquisarEscolaPorNome(
    String nomePesquisa,
  ) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      final DatabaseReference escolasRef = _database.ref(
        'users/${user.uid}/escolas',
      );
      final DataSnapshot snapshot = await escolasRef.get();

      if (!snapshot.exists) {
        return [];
      }

      final List<Map<String, dynamic>> escolas = [];
      if (snapshot.value is Map) {
        (snapshot.value as Map).forEach((key, value) {
          String nomeEscola = value['nome'];
          // Verifica se o nome da escola contém a string de pesquisa
          if (nomeEscola.toLowerCase().contains(nomePesquisa.toLowerCase())) {
            escolas.add({
              'id': key,
              'nome': nomeEscola,
              'endereco': value['endereco'],
              'contato': value['contato'],
            });
          }
        });
      }

      escolas.sort((a, b) => a['nome'].compareTo(b['nome']));

      return escolas;
    } catch (e) {
      throw Exception('Erro ao pesquisar a escola: $e');
    }
  }

  /// Abre o WhatsApp para o aluno usando o contato selecionado (1 ou 2).
  Future<void> abrirWhatsappAluno(
    String alunoId, {
    int contatoSelecionado = 1,
  }) async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Usuário não autenticado.');
      }

      final String userId = currentUser.uid;
      final DatabaseReference alunoRef = _database.ref(
        'users/$userId/alunos/$alunoId',
      );
      final DataSnapshot snapshot = await alunoRef.get();

      if (!snapshot.exists || snapshot.value == null) {
        throw Exception('Aluno não encontrado.');
      }

      final Map<dynamic, dynamic> alunoData =
          snapshot.value as Map<dynamic, dynamic>;
      String? telefone;
      if (contatoSelecionado == 1) {
        telefone = alunoData['telefone1']?.toString();
      } else if (contatoSelecionado == 2) {
        telefone = alunoData['telefone2']?.toString();
      } else {
        throw Exception('Contato selecionado inválido. Escolha 1 ou 2.');
      }

      if (telefone == null || telefone.isEmpty) {
        throw Exception(
          'Telefone $contatoSelecionado não encontrado para o aluno.',
        );
      }

      // Formata o número: remove '+' se existir e adiciona o código do país 55 se necessário
      String numero = telefone;
      if (numero.startsWith('+55')) {
        numero = numero.substring(1);
      } else if (!numero.startsWith('55')) {
        numero = '55' + numero;
      }

      final String url = 'https://wa.me/$numero';

      if (await canLaunch(url)) {
        await launch(url);
      } else {
        throw Exception('Não foi possível abrir o WhatsApp.');
      }
    } catch (e) {
      throw Exception('Erro ao abrir o WhatsApp: $e');
    }
  }
}
