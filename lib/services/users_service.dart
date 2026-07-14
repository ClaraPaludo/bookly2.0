import '../database/app_database.dart';

class UsersService {
  static Future<Map<String, dynamic>> createUser({
    required String name,
    required String email,
    required String password,
    String? profilePhotoUrl,
  }) async {
    final db = await AppDatabase.database;
    final now = DateTime.now().toIso8601String();

    final id = await db.insert('users', {
      'name': name.trim().isEmpty ? 'User123' : name.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
      'profilePhotoUrl': profilePhotoUrl,
      'createdAt': now,
      'updatedAt': now,
    });

    final user = await getUserById(id.toString());

    if (user == null) {
      throw Exception('Erro ao criar usuário.');
    }

    return user;
  }

  static Future<List<Map<String, dynamic>>> listUsers({String? search}) async {
    final db = await AppDatabase.database;

    final hasSearch = search != null && search.trim().isNotEmpty;

    final result = await db.query(
      'users',
      where: hasSearch ? 'name LIKE ? OR email LIKE ?' : null,
      whereArgs: hasSearch ? ['%${search.trim()}%', '%${search.trim()}%'] : null,
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

    if (result.isEmpty) return null;

    return Map<String, dynamic>.from(result.first);
  }

  static Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await AppDatabase.database;

    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return Map<String, dynamic>.from(result.first);
  }

  static Future<Map<String, dynamic>> updateUser({
    required String id,
    String? name,
    String? email,
    String? password,
    String? profilePhotoUrl,
  }) async {
    final db = await AppDatabase.database;

    final data = <String, dynamic>{
      'updatedAt': DateTime.now().toIso8601String(),
    };

    if (name != null) {
      data['name'] = name.trim().isEmpty ? 'User123' : name.trim();
    }

    if (email != null) {
      data['email'] = email.trim().toLowerCase();
    }

    if (password != null) {
      data['password'] = password;
    }

    if (profilePhotoUrl != null) {
      data['profilePhotoUrl'] = profilePhotoUrl;
    }

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

  static Future<int> countUsers() async {
    final db = await AppDatabase.database;

    final result = await db.rawQuery('SELECT COUNT(*) AS total FROM users');

    return result.first['total'] as int? ?? 0;
  }
}