import '../database/app_database.dart';

class FriendsService {
  static Future<Map<String, dynamic>> createFriend({
    required String userId,
    required String name,
    String? email,
    String? phone,
    String? notes,
  }) async {
    final db = await AppDatabase.database;

    final id = await db.insert('friends', {
      'userId': int.parse(userId),
      'name': name,
      'email': email,
      'phone': phone,
      'notes': notes,
      'createdAt': DateTime.now().toIso8601String(),
    });

    final friend = await getFriendById(id.toString());

    if (friend == null) {
      throw Exception('Erro ao criar amigo.');
    }

    return friend;
  }

  static Future<List<Map<String, dynamic>>> listFriends({
    String? userId,
  }) async {
    final db = await AppDatabase.database;

    final result = await db.query(
      'friends',
      where: userId == null ? null : 'userId = ?',
      whereArgs: userId == null ? null : [int.parse(userId)],
      orderBy: 'createdAt DESC',
    );

    final friends = <Map<String, dynamic>>[];

    for (final item in result) {
      final friend = Map<String, dynamic>.from(item);

      final loans = await db.rawQuery(
        '''
        SELECT 
          loans.*,
          books.title AS bookTitle,
          books.author AS bookAuthor
        FROM loans
        LEFT JOIN books ON books.id = loans.bookId
        WHERE loans.friendId = ?
        ORDER BY loans.createdAt DESC
        ''',
        [friend['id']],
      );

      friend['loans'] = loans.map((loan) {
        final loanMap = Map<String, dynamic>.from(loan);

        loanMap['book'] = {
          'title': loanMap['bookTitle'],
          'author': loanMap['bookAuthor'],
        };

        return loanMap;
      }).toList();

      friends.add(friend);
    }

    return friends;
  }

  static Future<Map<String, dynamic>?> getFriendById(String id) async {
    final db = await AppDatabase.database;

    final result = await db.query(
      'friends',
      where: 'id = ?',
      whereArgs: [int.parse(id)],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return Map<String, dynamic>.from(result.first);
  }

  static Future<Map<String, dynamic>> updateFriend({
    required String id,
    String? name,
    String? email,
    String? phone,
    String? notes,
  }) async {
    final db = await AppDatabase.database;

    final data = <String, dynamic>{};

    if (name != null) data['name'] = name;
    if (email != null) data['email'] = email;
    if (phone != null) data['phone'] = phone;
    if (notes != null) data['notes'] = notes;

    await db.update(
      'friends',
      data,
      where: 'id = ?',
      whereArgs: [int.parse(id)],
    );

    final friend = await getFriendById(id);

    if (friend == null) {
      throw Exception('Amigo não encontrado.');
    }

    return friend;
  }

  static Future<void> deleteFriend(String id) async {
    final db = await AppDatabase.database;

    await db.delete(
      'friends',
      where: 'id = ?',
      whereArgs: [int.parse(id)],
    );
  }
}