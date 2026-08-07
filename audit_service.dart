import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/audit_model.dart';
import '../utils/constants.dart';
import 'auth_service.dart';

class AuditService {
  AuditService._internal();
  static final AuditService instance = AuditService._internal();

  final _uuid = const Uuid();

  Future<void> log({
    required AuditAction action,
    required String entityType,
    required String entityId,
    String description = '',
  }) async {
    final currentUser = AuthService.instance.currentUser;
    final entry = AuditModel(
      id: _uuid.v4(),
      userId: currentUser?.id ?? 'system',
      userName: currentUser?.name ?? 'System',
      action: action,
      entityType: entityType,
      entityId: entityId,
      description: description,
      timestamp: DateTime.now(),
    );

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(AppConstants.prefsAuditKey) ?? [];
    raw.add(jsonEncode(entry.toMap()));
    // Keep the audit log bounded so local storage doesn't grow unbounded.
    if (raw.length > 2000) {
      raw.removeRange(0, raw.length - 2000);
    }
    await prefs.setStringList(AppConstants.prefsAuditKey, raw);
  }

  Future<List<AuditModel>> getLogs({int limit = 200}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(AppConstants.prefsAuditKey) ?? [];
    final logs = raw.map((s) => AuditModel.fromMap(jsonDecode(s))).toList();
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return logs.take(limit).toList();
  }
}
