import '../database/app_database.dart';

class LoansService {

  static Future<void> updateLoanPhotos({
  required String id,
  String? beforePhotoUrl,
  String? afterPhotoUrl,
}) async {
  final db = await AppDatabase.database;

  final data = <String, dynamic>{
    'updatedAt': DateTime.now().toIso8601String(),
  };

  // Só atualiza a foto antes se uma nova imagem foi escolhida.
  if (beforePhotoUrl != null) {
    data['beforePhotoUrl'] = beforePhotoUrl;
  }

  // Só atualiza a foto depois se uma nova imagem foi escolhida.
  if (afterPhotoUrl != null) {
    data['afterPhotoUrl'] = afterPhotoUrl;
  }

  await db.update(
    'loans',
    data,
    where: 'id = ?',
    whereArgs: [id],
  );
}
  // Cria um novo empréstimo.
  //
  // Aqui acontece uma regra importante:
  // quando o livro é emprestado, ele deixa de ficar disponível.
  //
  // Também salvamos a foto "antes do empréstimo", caso o usuário envie.
  static Future<Map<String, dynamic>> createLoan({
    required String userId,
    required String friendId,
    required String bookId,
    DateTime? loanDate,
    required DateTime dueDate,
    String? notes,
    

    // Campo antigo. Mantemos para compatibilidade com partes antigas do app.
    String? photoUrl,

    // Foto do livro antes de emprestar.
    // Vai ser salva como texto base64 no SQLite.
    String? beforePhotoUrl,

    bool reminderEnabled = true,
    int reminderDaysBefore = 1,
  }) async {
    final db = await AppDatabase.database;

    final now = DateTime.now();
    final loanDateValue = loanDate ?? now;

    late int loanId;

    await db.transaction((txn) async {
      // Antes de criar o empréstimo, buscamos o livro no banco.
      final bookResult = await txn.query(
        'books',
        where: 'id = ?',
        whereArgs: [int.parse(bookId)],
        limit: 1,
      );

      if (bookResult.isEmpty) {
        throw Exception('Livro não encontrado.');
      }

      final book = Map<String, dynamic>.from(bookResult.first);

      // No SQLite, booleano costuma ser salvo como 0 ou 1.
      final available = book['available'] == 1 || book['available'] == true;

      if (!available) {
        throw Exception('Este livro já está emprestado.');
      }

      // Cria o empréstimo.
      loanId = await txn.insert('loans', {
        'userId': int.parse(userId),
        'friendId': int.parse(friendId),
        'bookId': int.parse(bookId),
        'loanDate': loanDateValue.toIso8601String(),
        'dueDate': dueDate.toIso8601String(),
        'returnedDate': null,
        'status': _calculateStatus(dueDate, null),
        'notes': notes,
        'photoUrl': photoUrl,

        // Foto tirada antes do empréstimo.
        'beforePhotoUrl': beforePhotoUrl,

        // A foto depois da devolução começa vazia.
        'afterPhotoUrl': null,

        'reminderEnabled': reminderEnabled ? 1 : 0,
        'reminderDaysBefore': reminderDaysBefore,
        'createdAt': now.toIso8601String(),
        'updatedAt': null,
      });

      // Assim que empresta, o livro fica indisponível.
      await txn.update(
        'books',
        {
          'available': 0,
          'updatedAt': now.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [int.parse(bookId)],
      );
    });

    final loan = await getLoanById(loanId.toString());

    if (loan == null) {
      throw Exception('Erro ao criar empréstimo.');
    }

    return loan;
  }

  // Lista empréstimos.
  //
  // Essa busca faz JOIN com friends e books.
  // Assim a tela consegue mostrar nome do amigo e título do livro
  // sem precisar fazer várias buscas separadas.
  static Future<List<Map<String, dynamic>>> listLoans({
    String? userId,
    String? status,
  }) async {
    final db = await AppDatabase.database;

    final whereParts = <String>[];
    final whereArgs = <dynamic>[];

    if (userId != null) {
      whereParts.add('loans.userId = ?');
      whereArgs.add(int.parse(userId));
    }

    if (status != null) {
      whereParts.add('loans.status = ?');
      whereArgs.add(status);
    }

    final result = await db.rawQuery(
      '''
      SELECT 
        loans.*,

        friends.id AS friend_id,
        friends.name AS friend_name,
        friends.email AS friend_email,
        friends.phone AS friend_phone,
        friends.notes AS friend_notes,

        books.id AS book_id,
        books.title AS book_title,
        books.author AS book_author,
        books.publisher AS book_publisher,
        books.category AS book_category,
        books.description AS book_description,
        books.coverUrl AS book_coverUrl,
        books.available AS book_available
      FROM loans
      LEFT JOIN friends ON friends.id = loans.friendId
      LEFT JOIN books ON books.id = loans.bookId
      ${whereParts.isEmpty ? '' : 'WHERE ${whereParts.join(' AND ')}'}
      ORDER BY loans.createdAt DESC
      ''',
      whereArgs,
    );

    return result.map(_loanFromJoin).toList();
  }

  // Busca um empréstimo específico pelo id.
  static Future<Map<String, dynamic>?> getLoanById(String id) async {
    final db = await AppDatabase.database;

    final result = await db.rawQuery(
      '''
      SELECT 
        loans.*,

        friends.id AS friend_id,
        friends.name AS friend_name,
        friends.email AS friend_email,
        friends.phone AS friend_phone,
        friends.notes AS friend_notes,

        books.id AS book_id,
        books.title AS book_title,
        books.author AS book_author,
        books.publisher AS book_publisher,
        books.category AS book_category,
        books.description AS book_description,
        books.coverUrl AS book_coverUrl,
        books.available AS book_available
      FROM loans
      LEFT JOIN friends ON friends.id = loans.friendId
      LEFT JOIN books ON books.id = loans.bookId
      WHERE loans.id = ?
      LIMIT 1
      ''',
      [int.parse(id)],
    );

    if (result.isEmpty) {
      return null;
    }

    return _loanFromJoin(result.first);
  }

  // Atualiza dados de um empréstimo.
  //
  // Vamos usar essa função para:
  // - editar prazo;
  // - salvar foto antes/depois;
  // - alterar status;
  // - adicionar observações.
  static Future<Map<String, dynamic>> updateLoan({
    required String id,
    String? friendId,
    String? bookId,
    DateTime? loanDate,
    DateTime? dueDate,
    DateTime? returnedDate,
    String? status,
    String? notes,
    String? photoUrl,

    // Foto antes do empréstimo.
    String? beforePhotoUrl,

    // Foto depois da devolução.
    String? afterPhotoUrl,

    bool? reminderEnabled,
    int? reminderDaysBefore,
  }) async {
    final db = await AppDatabase.database;
    final now = DateTime.now();

    final data = <String, dynamic>{
      'updatedAt': now.toIso8601String(),
    };

    if (friendId != null) data['friendId'] = int.parse(friendId);
    if (bookId != null) data['bookId'] = int.parse(bookId);
    if (loanDate != null) data['loanDate'] = loanDate.toIso8601String();
    if (dueDate != null) data['dueDate'] = dueDate.toIso8601String();
    if (returnedDate != null) {
      data['returnedDate'] = returnedDate.toIso8601String();
    }
    if (status != null) data['status'] = status;
    if (notes != null) data['notes'] = notes;
    if (photoUrl != null) data['photoUrl'] = photoUrl;
    if (beforePhotoUrl != null) data['beforePhotoUrl'] = beforePhotoUrl;
    if (afterPhotoUrl != null) data['afterPhotoUrl'] = afterPhotoUrl;
    if (reminderEnabled != null) {
      data['reminderEnabled'] = reminderEnabled ? 1 : 0;
    }
    if (reminderDaysBefore != null) {
      data['reminderDaysBefore'] = reminderDaysBefore;
    }

    await db.update(
      'loans',
      data,
      where: 'id = ?',
      whereArgs: [int.parse(id)],
    );

    final loan = await getLoanById(id);

    if (loan == null) {
      throw Exception('Empréstimo não encontrado.');
    }

    return loan;
  }

  // Marca um empréstimo como devolvido.
  //
  // Também libera o livro para aparecer novamente como disponível.
  //
  // Agora aceita afterPhotoUrl, que é a foto do livro depois da devolução.
  static Future<Map<String, dynamic>> markLoanAsReturned(
    String id, {
    String? afterPhotoUrl,
  }) async {
    final db = await AppDatabase.database;
    final returnedDate = DateTime.now();

    await db.transaction((txn) async {
      final loanResult = await txn.query(
        'loans',
        where: 'id = ?',
        whereArgs: [int.parse(id)],
        limit: 1,
      );

      if (loanResult.isEmpty) {
        throw Exception('Empréstimo não encontrado.');
      }

      final loan = Map<String, dynamic>.from(loanResult.first);

      await txn.update(
        'loans',
        {
          'returnedDate': returnedDate.toIso8601String(),
          'status': 'RETURNED',

          // Salva a foto de como o livro voltou, se o usuário enviou.
          'afterPhotoUrl': afterPhotoUrl,

          'updatedAt': returnedDate.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [int.parse(id)],
      );

      // Devolve o livro para a lista de disponíveis.
      await txn.update(
        'books',
        {
          'available': 1,
          'updatedAt': returnedDate.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [loan['bookId']],
      );
    });

    final loan = await getLoanById(id);

    if (loan == null) {
      throw Exception('Empréstimo não encontrado.');
    }

    return loan;
  }

  // Exclui um empréstimo.
  //
  // Se o empréstimo for removido, o livro volta a ficar disponível.
  static Future<void> deleteLoan(String id) async {
    final db = await AppDatabase.database;
    final now = DateTime.now();

    await db.transaction((txn) async {
      final loanResult = await txn.query(
        'loans',
        where: 'id = ?',
        whereArgs: [int.parse(id)],
        limit: 1,
      );

      if (loanResult.isNotEmpty) {
        final loan = Map<String, dynamic>.from(loanResult.first);

        await txn.update(
          'books',
          {
            'available': 1,
            'updatedAt': now.toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [loan['bookId']],
        );
      }

      await txn.delete(
        'loans',
        where: 'id = ?',
        whereArgs: [int.parse(id)],
      );
    });
  }

  // Atualiza empréstimos vencidos.
  //
  // Exemplo:
  // se hoje já passou da data de devolução,
  // o status muda de PENDING para LATE.
  static Future<void> refreshLoanStatuses({String? userId}) async {
    final db = await AppDatabase.database;

    final where = userId == null
        ? "status != 'RETURNED'"
        : "userId = ? AND status != 'RETURNED'";

    final whereArgs = userId == null ? null : [int.parse(userId)];

    final loans = await db.query(
      'loans',
      where: where,
      whereArgs: whereArgs,
    );

    final now = DateTime.now();

    for (final item in loans) {
      final loan = Map<String, dynamic>.from(item);
      final dueDate = DateTime.tryParse(loan['dueDate']?.toString() ?? '');

      if (dueDate == null) {
        continue;
      }

      final newStatus = _calculateStatus(dueDate, null);

      if (newStatus != loan['status']) {
        await db.update(
          'loans',
          {
            'status': newStatus,
            'updatedAt': now.toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [loan['id']],
        );
      }
    }
  }

  // Calcula o status do empréstimo com base na data.
  static String _calculateStatus(DateTime dueDate, DateTime? returnedDate) {
    if (returnedDate != null) {
      return 'RETURNED';
    }

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final dueOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);

    if (dueOnly.isBefore(todayOnly)) {
      return 'LATE';
    }

    return 'PENDING';
  }

  // Converte o resultado do JOIN em um Map mais fácil de usar nas telas.
  //
  // Em vez de a tela receber só friend_id e book_title,
  // ela recebe também:
  // loan['friend']
  // loan['book']
  static Map<String, dynamic> _loanFromJoin(Map<String, dynamic> item) {
    final loan = Map<String, dynamic>.from(item);

    loan['reminderEnabled'] =
        loan['reminderEnabled'] == 1 || loan['reminderEnabled'] == true;

    loan['friend'] = {
      'id': item['friend_id'],
      'name': item['friend_name'],
      'email': item['friend_email'],
      'phone': item['friend_phone'],
      'notes': item['friend_notes'],
    };

    loan['book'] = {
      'id': item['book_id'],
      'title': item['book_title'],
      'author': item['book_author'],
      'publisher': item['book_publisher'],
      'category': item['book_category'],
      'description': item['book_description'],
      'coverUrl': item['book_coverUrl'],
      'available': item['book_available'] == 1 || item['book_available'] == true,
    };

    return loan;
  }
}