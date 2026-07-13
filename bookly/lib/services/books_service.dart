import '../database/app_database.dart';

class BooksService {
  static Future<Map<String, dynamic>> createBook({
    required String userId,
    required String title,
    required String author,
    String? publisher,
    String? category,
    String? description,
    String? coverUrl,
  }) async {
    final db = await AppDatabase.database;

    final id = await db.insert('books', {
      'userId': int.parse(userId),
      'title': title,
      'author': author,
      'publisher': publisher,
      'category': category,
      'description': description,
      'coverUrl': coverUrl,
      'available': 1,
      'createdAt': DateTime.now().toIso8601String(),
    });

    final book = await getBookById(id.toString());

    if (book == null) {
      throw Exception('Erro ao criar livro.');
    }

    return book;
  }

  static Future<List<Map<String, dynamic>>> listBooks({
    String? userId,
    bool? available,
  }) async {
    final db = await AppDatabase.database;

    final whereParts = <String>[];
    final whereArgs = <dynamic>[];

    if (userId != null) {
      whereParts.add('userId = ?');
      whereArgs.add(int.parse(userId));
    }

    if (available != null) {
      whereParts.add('available = ?');
      whereArgs.add(available ? 1 : 0);
    }

    final result = await db.query(
      'books',
      where: whereParts.isEmpty ? null : whereParts.join(' AND '),
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'createdAt DESC',
    );

    return result.map((item) {
      final map = Map<String, dynamic>.from(item);
      map['available'] = map['available'] == 1;
      return map;
    }).toList();
  }

  static Future<Map<String, dynamic>?> getBookById(String id) async {
    final db = await AppDatabase.database;

    final result = await db.query(
      'books',
      where: 'id = ?',
      whereArgs: [int.parse(id)],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    final map = Map<String, dynamic>.from(result.first);
    map['available'] = map['available'] == 1;

    return map;
  }

  static Future<Map<String, dynamic>> updateBook({
    required String id,
    String? title,
    String? author,
    String? publisher,
    String? category,
    String? description,
    String? coverUrl,
    bool? available,
  }) async {
    final db = await AppDatabase.database;

    final data = <String, dynamic>{};

    if (title != null) data['title'] = title;
    if (author != null) data['author'] = author;
    if (publisher != null) data['publisher'] = publisher;
    if (category != null) data['category'] = category;
    if (description != null) data['description'] = description;
    if (coverUrl != null) data['coverUrl'] = coverUrl;
    if (available != null) data['available'] = available ? 1 : 0;

    await db.update(
      'books',
      data,
      where: 'id = ?',
      whereArgs: [int.parse(id)],
    );

    final book = await getBookById(id);

    if (book == null) {
      throw Exception('Livro não encontrado.');
    }

    return book;
  }

  static Future<void> deleteBook(String id) async {
    final db = await AppDatabase.database;

    await db.delete(
      'books',
      where: 'id = ?',
      whereArgs: [int.parse(id)],
    );
  }
}