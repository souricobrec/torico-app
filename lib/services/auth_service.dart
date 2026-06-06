import '../models/app_user.dart';

class AuthService {
  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    return AppUser(id: 'user_001', name: 'Dono do negócio', email: email);
  }
}
