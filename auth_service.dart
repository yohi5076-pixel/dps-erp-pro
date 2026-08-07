import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import 'firestore_service.dart';

/// Handles authentication, session persistence, and user management.
/// Backed by FirestoreService's local store so it works offline out of
/// the box; swap the internals for real Firebase Auth later if needed.
class AuthService {
  AuthService._internal();
  static final AuthService instance = AuthService._internal();

  final _uuid = const Uuid();
  UserModel? currentUser;

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  /// Ensures a default admin account exists on first run.
  Future<void> seedDefaultAdminIfNeeded() async {
    final users = await FirestoreService.instance.getUsers();
    if (users.isEmpty) {
      final admin = UserModel(
        id: _uuid.v4(),
        name: 'Administrator',
        email: 'admin@dps.local',
        passwordHash: _hashPassword('admin123'),
        role: UserRole.admin,
        createdAt: DateTime.now(),
      );
      await FirestoreService.instance.saveUser(admin);
    }
  }

  Future<UserModel?> login(String email, String password) async {
    final users = await FirestoreService.instance.getUsers();
    final hashed = _hashPassword(password);
    final matches = users.where(
      (u) => u.email.toLowerCase() == email.toLowerCase() && u.passwordHash == hashed && u.isActive,
    );
    if (matches.isEmpty) return null;

    final user = matches.first;
    currentUser = user;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefsSessionKey, user.id);
    return user;
  }

  Future<void> logout() async {
    currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.prefsSessionKey);
  }

  /// Attempts to restore a previous session on app start.
  Future<UserModel?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(AppConstants.prefsSessionKey);
    if (userId == null) return null;

    final users = await FirestoreService.instance.getUsers();
    final matches = users.where((u) => u.id == userId && u.isActive);
    if (matches.isEmpty) return null;

    currentUser = matches.first;
    return currentUser;
  }

  Future<UserModel> createUser({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final user = UserModel(
      id: _uuid.v4(),
      name: name,
      email: email,
      passwordHash: _hashPassword(password),
      role: role,
      createdAt: DateTime.now(),
    );
    await FirestoreService.instance.saveUser(user);
    return user;
  }

  Future<void> changePassword(String userId, String newPassword) async {
    final users = await FirestoreService.instance.getUsers();
    final user = users.firstWhere((u) => u.id == userId);
    final updated = user.copyWith(passwordHash: _hashPassword(newPassword));
    await FirestoreService.instance.saveUser(updated);
    if (currentUser?.id == userId) currentUser = updated;
  }

  bool get isAdmin => currentUser?.role == UserRole.admin;
  bool get isManager => currentUser?.role == UserRole.manager || isAdmin;
}
