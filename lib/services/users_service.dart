import '../database/app_database.dart';

class UsersService {
  static Future<Map<String, dynamic>> createUser({
    required String name,
    required String email,
    required String password,
  }) async {
    final db = await AppDatabase.database;

    final id = await db.insert('users', {
      'name': name,
      'email': email,
      'password': password,
      'createdAt': DateTime.now().toIso8601String(),
    });

    final user = await getUserById(id.toString());

    if (user == null) {
      throw Exception('Erro ao criar usuário.');
    }

    return user;
  }

  static Future<List<Map<String, dynamic>>> listUsers() async {
    final db = await AppDatabase.database;

    final result = await db.query(
      'users',
      orderBy: 'createdAt DESC',
    );

    return result.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  static Future<Map<String, dynamic>?> getUserById(String id) async {
    final db = await AppDatabase.database;

    final result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [int.parse(id)],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return Map<String, dynamic>.from(result.first);
  }

  static Future<Map<String, dynamic>> updateUser({
    required String id,
    String? name,
    String? email,
    String? password,
  }) async {
    final db = await AppDatabase.database;

    final data = <String, dynamic>{};

    if (name != null) data['name'] = name;
    if (email != null) data['email'] = email;
    if (password != null) data['password'] = password;

    await db.update(
      'users',
      data,
      where: 'id = ?',
      whereArgs: [int.parse(id)],
    );

    final user = await getUserById(id);

    if (user == null) {
      throw Exception('Usuário não encontrado.');
    }

    return user;
  }

  static Future<void> deleteUser(String id) async {
    final db = await AppDatabase.database;

    await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [int.parse(id)],
    );
  }
}