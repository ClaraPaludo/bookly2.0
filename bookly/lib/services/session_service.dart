import 'users_service.dart';

class SessionService {
  static const String temporaryUserEmail = 'usuario@bookly.com';

  static Map<String, dynamic>? _currentUser;

  static Future<Map<String, dynamic>> getCurrentUser() async {
    if (_currentUser != null) {
      return _currentUser!;
    }

    final users = await UsersService.listUsers();

    for (final user in users) {
      final email = user['email']?.toString();

      if (email == temporaryUserEmail) {
        _currentUser = user;
        return _currentUser!;
      }
    }

    _currentUser = await UsersService.createUser(
      name: 'Usuário Bookly',
      email: temporaryUserEmail,
      password: '123456',
    );

    return _currentUser!;
  }

  static Future<String> getCurrentUserId() async {
    final user = await getCurrentUser();
    return user['id'].toString();
  }

  static void clearSession() {
    _currentUser = null;
  }
}