import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class AuthService {
  bool get hasSession;

  Stream<bool> get authStateChanges;

  Future<void> signIn({required String email, required String password});

  Future<bool> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  });

  Future<void> resetPassword(String email);

  Future<void> signOut();
}

class SupabaseAuthService implements AuthService {
  SupabaseAuthService(this._client);

  final SupabaseClient _client;

  @override
  bool get hasSession => _client.auth.currentSession != null;

  @override
  Stream<bool> get authStateChanges => _client.auth.onAuthStateChange
      .map((state) => state.session != null)
      .distinct();

  @override
  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<bool> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'nombre': firstName.trim(), 'apellido': lastName.trim()},
    );
    return response.session != null;
  }

  @override
  Future<void> resetPassword(String email) {
    return _client.auth.resetPasswordForEmail(email.trim());
  }

  @override
  Future<void> signOut() {
    return _client.auth.signOut(scope: SignOutScope.local);
  }
}
