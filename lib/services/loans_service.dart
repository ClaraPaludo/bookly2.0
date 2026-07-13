
import '../database/app_database.dart';

class LoansService {
  static Future<Map<String, dynamic>> createLoan({
    required String userId,
    required String friendId,
    required String bookId,
    DateTime? loanDate,
    required DateTime dueDate,
    String? notes,
    String? photoUrl,
  }) async {
    final db = await AppDatabase.database;

    final now = DateTime.now();
    final loanDateValue = loanDate ?? now;

    late int loanId;

    await db.transaction((txn) async {
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
      final available = book['available'] == 1;

      if (!available) {
        throw Exception('Este livro já está emprestado.');
      }

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
        'createdAt': now.toIso8601String(),
      });

      await txn.update(
        'books',
        {'available': 0},
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
  }) async {
    final db = await AppDatabase.database;

    final data = <String, dynamic>{};

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

  static Future<Map<String, dynamic>> markLoanAsReturned(String id) async {
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
        },
        where: 'id = ?',
        whereArgs: [int.parse(id)],
      );

      await txn.update(
        'books',
        {'available': 1},
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

  static Future<void> deleteLoan(String id) async {
    final db = await AppDatabase.database;

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
          {'available': 1},
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

  static Map<String, dynamic> _loanFromJoin(Map<String, dynamic> item) {
    final loan = Map<String, dynamic>.from(item);

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
      'available': item['book_available'] == 1,
    };

    return loan;
  }
}