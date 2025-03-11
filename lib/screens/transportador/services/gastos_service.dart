import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class GastosService {
  /// Cria um gasto no Realtime Database.
  ///
  /// Os dados serão salvos em: users/[user.uid]/gastos/[gastoid]
  ///
  /// Parâmetros:
  /// - [description]: Descrição do gasto.
  /// - [day]: Dia da data do gasto.
  /// - [month]: Mês da data do gasto.
  /// - [year]: Ano da data do gasto.
  /// - [category]: Categoria do gasto (ex.: "mecânico", "peças", "gasolina", "ajudante", "garagem", "outros").
  /// - [value]: Valor do gasto.
  Future<void> createGasto({
    required String description,
    required int day,
    required int month,
    required int year,
    required String category,
    required double value,
  }) async {
    // Verifica se o usuário está autenticado.
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("Usuário não autenticado");
    }

    // Consulta o plano do usuário
    final DatabaseReference planRef = FirebaseDatabase.instance.ref(
      'users/${user.uid}/userInfos/plano',
    );
    final planSnapshot = await planRef.get();
    if (!planSnapshot.exists) {
      throw Exception("Plano do usuário não encontrado");
    }

    // Define o limite de gastos com base no plano
    final plan = planSnapshot.value;
    int gastoLimite;
    if (plan == 0) {
      gastoLimite = 5;
    } else if (plan == 1) {
      gastoLimite = 50;
    } else {
      throw Exception("Plano inválido");
    }

    // Verifica quantos gastos já existem para o mês e ano informados
    final currentGastos = await getGastos(month: month, year: year);
    if (currentGastos.length >= gastoLimite) {
      throw Exception("Limite de gastos atingido para o seu plano.");
    }

    // Validação simples da categoria.
    const validCategories = [
      'mecânico',
      'peças',
      'gasolina',
      'ajudante',
      'garagem',
      'outros',
    ];
    if (!validCategories.contains(category.toLowerCase())) {
      throw Exception(
        "Categoria inválida. Utilize uma das seguintes: $validCategories",
      );
    }

    // Monta o caminho no Realtime Database: users/[user.uid]/gastos
    final DatabaseReference gastosRef = FirebaseDatabase.instance.ref(
      'users/${user.uid}/gastos',
    );

    // Cria um novo nó com ID único para o gasto
    final DatabaseReference newGastoRef = gastosRef.push();

    // Monta o mapa com os dados do gasto
    final gastoData = {
      'description': description,
      'day': day,
      'month': month,
      'year': year,
      'category': category,
      'value': value,
    };

    // Salva os dados no banco de dados
    await newGastoRef.set(gastoData);
  }

  /// Lista os gastos do usuário filtrados pelo [month] e [year] de forma pontual.
  ///
  /// Retorna uma lista de mapas, onde cada mapa representa um gasto e contém
  /// os dados armazenados, além da chave [id] (identificador do gasto no banco).
  Future<List<Map<String, dynamic>>> getGastos({
    required int month,
    required int year,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("Usuário não autenticado");
    }

    final DatabaseReference gastosRef = FirebaseDatabase.instance.ref(
      'users/${user.uid}/gastos',
    );

    // Obtém os dados do nó de gastos
    final snapshot = await gastosRef.get();
    List<Map<String, dynamic>> gastosList = [];

    if (snapshot.exists) {
      // O snapshot.value geralmente é um Map
      final data = snapshot.value as Map<dynamic, dynamic>;
      data.forEach((key, value) {
        final gastoMap = Map<String, dynamic>.from(value);
        // Filtra de acordo com o mês e ano
        if (gastoMap['month'] == month && gastoMap['year'] == year) {
          gastoMap['id'] = key; // Adiciona o identificador do gasto
          gastosList.add(gastoMap);
        }
      });
    }

    return gastosList;
  }

  /// Retorna um Stream que emite uma lista de gastos filtrados pelo [month] e [year].
  ///
  /// Dessa forma, a interface pode utilizar um StreamBuilder para atualizar automaticamente
  /// a lista sempre que houver alteração no banco de dados (edição, exclusão ou criação).
  Stream<List<Map<String, dynamic>>> getGastosStream({
    required int month,
    required int year,
  }) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("Usuário não autenticado");
    }
    final DatabaseReference gastosRef = FirebaseDatabase.instance.ref(
      'users/${user.uid}/gastos',
    );

    return gastosRef.onValue.map((event) {
      List<Map<String, dynamic>> gastosList = [];
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          final gastoMap = Map<String, dynamic>.from(value);
          if (gastoMap['month'] == month && gastoMap['year'] == year) {
            gastoMap['id'] = key;
            gastosList.add(gastoMap);
          }
        });
      }
      return gastosList;
    });
  }

  /// Exclui o gasto identificado por [gastoId] do Realtime Database.
  Future<void> deleteGasto(String gastoId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("Usuário não autenticado");
    }

    final DatabaseReference gastoRef = FirebaseDatabase.instance.ref(
      'users/${user.uid}/gastos/$gastoId',
    );

    await gastoRef.remove();
  }

  /// Atualiza (edita) o gasto identificado por [gastoId] com os novos dados.
  Future<void> updateGasto({
    required String gastoId,
    required String description,
    required int day,
    required int month,
    required int year,
    required String category,
    required double value,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("Usuário não autenticado");
    }

    // Validação simples da categoria.
    const validCategories = [
      'mecânico',
      'peças',
      'gasolina',
      'ajudante',
      'garagem',
      'outros',
    ];
    if (!validCategories.contains(category.toLowerCase())) {
      throw Exception(
        "Categoria inválida. Utilize uma das seguintes: $validCategories",
      );
    }

    final DatabaseReference gastoRef = FirebaseDatabase.instance.ref(
      'users/${user.uid}/gastos/$gastoId',
    );

    final updatedData = {
      'description': description,
      'day': day,
      'month': month,
      'year': year,
      'category': category,
      'value': value,
    };

    await gastoRef.update(updatedData);
  }
}
