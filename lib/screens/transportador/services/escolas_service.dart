import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class EscolasService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // Função para verificar o plano do usuário e retornar o número máximo de escolas
  Future<int> getMaxEscolas() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      final DatabaseReference userRef = _database.ref(
        'users/${user.uid}/userInfos/plano',
      );
      final DataSnapshot snapshot = await userRef.get();

      if (!snapshot.exists) {
        throw Exception('Plano não encontrado para o usuário');
      }

      final String planoString = snapshot.value.toString();
      final int plano = int.tryParse(planoString) ?? 0;

      if (plano == 0) {
        return 5;
      } else if (plano == 1) {
        return 50;
      } else {
        throw Exception('Plano inválido');
      }
    } catch (e) {
      throw Exception('Erro ao obter o plano do usuário: $e');
    }
  }

  // Função para verificar quantas escolas estão registradas para o usuário
  Future<int> getNumeroDeEscolas() async {
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
        return 0;
      }

      if (snapshot.value is Map) {
        return (snapshot.value as Map).length;
      } else if (snapshot.value is List) {
        return (snapshot.value as List).length;
      } else {
        return 0;
      }
    } catch (e) {
      throw Exception('Erro ao obter o número de escolas: $e');
    }
  }

  // Função para registrar uma nova escola
  Future<void> registrarEscola({
    required String nome,
    required String endereco,
    required String contato,
  }) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      // Verificando o número máximo de escolas permitido pelo plano do usuário
      final int maxEscolas = await getMaxEscolas();
      final int numeroDeEscolas = await getNumeroDeEscolas();

      // Verificando se o usuário atingiu o limite de escolas
      if (numeroDeEscolas >= maxEscolas) {
        throw Exception(
          'Você atingiu o número máximo de escolas permitidas no seu plano.',
        );
      }

      // Caminho para a referência das escolas do usuário no banco de dados
      final DatabaseReference escolasRef = _database.ref(
        'users/${user.uid}/escolas',
      );

      // Gerando um novo ID único para a escola
      final newEscolaRef = escolasRef.push();

      // Dados da escola a ser registrada
      final escolaData = {
        'nome': nome,
        'endereco': endereco,
        'contato': contato,
      };

      // Registrando a escola no Firebase
      await newEscolaRef.set(escolaData);

      print("Escola registrada com sucesso!");
    } catch (e) {
      throw Exception('Erro ao registrar a escola: $e');
    }
  }

  // Função para obter a lista de escolas do usuário
  Future<List<Map<String, dynamic>>> getListaEscolas() async {
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
          escolas.add({
            'id': key,
            'nome': value['nome'],
            'endereco': value['endereco'],
            'contato': value['contato'],
          });
        });
      }

      escolas.sort((a, b) => a['nome'].compareTo(b['nome']));

      return escolas;
    } catch (e) {
      throw Exception('Erro ao obter as escolas: $e');
    }
  }

  // Função para excluir uma escola
  Future<void> excluirEscola(String escolaId) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      final DatabaseReference escolaRef = _database.ref(
        'users/${user.uid}/escolas/$escolaId',
      );
      await escolaRef.remove();
    } catch (e) {
      throw Exception('Erro ao excluir a escola: $e');
    }
  }

  // Função para editar uma escola
  Future<void> editarEscola(
    String escolaId,
    String nome,
    String endereco,
    String contato,
  ) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      final DatabaseReference escolaRef = _database.ref(
        'users/${user.uid}/escolas/$escolaId',
      );
      await escolaRef.update({
        'nome': nome,
        'endereco': endereco,
        'contato': contato,
      });
    } catch (e) {
      throw Exception('Erro ao editar a escola: $e');
    }
  }

  // Função para pesquisar escolas pelo nome
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

      final List<Map<String, dynamic>> escolasFiltradas = [];
      if (snapshot.value is Map) {
        (snapshot.value as Map).forEach((key, value) {
          final nomeEscola = value['nome']?.toString().toLowerCase() ?? '';
          if (nomeEscola.contains(nomePesquisa.toLowerCase())) {
            escolasFiltradas.add({
              'id': key,
              'nome': value['nome'],
              'endereco': value['endereco'],
              'contato': value['contato'],
            });
          }
        });
      }

      // Ordenar os resultados por nome
      escolasFiltradas.sort((a, b) => a['nome'].compareTo(b['nome']));

      return escolasFiltradas;
    } catch (e) {
      throw Exception('Erro ao pesquisar escolas: $e');
    }
  }

  Future<void> abrirWhatsapp(String escolaId) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      final DatabaseReference contatoRef = _database.ref(
        'users/${user.uid}/escolas/$escolaId/contato',
      );
      final DataSnapshot snapshot = await contatoRef.get();

      if (!snapshot.exists || snapshot.value == null) {
        throw Exception('Contato não encontrado');
      }

      final String contato = snapshot.value.toString();

      // Formatar o número: remover '+' se presente e adicionar '55' caso não esteja presente
      String numero = contato;
      if (numero.startsWith('+55')) {
        numero = numero.substring(1); // remove o sinal de '+'
      } else if (!numero.startsWith('55')) {
        numero = '55' + numero;
      }

      final String url = 'https://wa.me/$numero';

      if (await canLaunch(url)) {
        await launch(url);
      } else {
        throw Exception('Não foi possível abrir o WhatsApp');
      }
    } catch (e) {
      throw Exception('Erro ao abrir o WhatsApp: $e');
    }
  }
}
