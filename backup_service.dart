import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

/// Exports and imports the entire local dataset as a single JSON file,
/// so users can back up or migrate data (and later, seed a real backend).
class BackupService {
  BackupService._internal();
  static final BackupService instance = BackupService._internal();

  static const _keys = [
    AppConstants.prefsUsersKey,
    AppConstants.prefsCustomersKey,
    AppConstants.prefsInvoicesKey,
    AppConstants.prefsPaymentsKey,
    AppConstants.prefsAuditKey,
  ];

  Future<File> exportBackup() async {
    final prefs = await SharedPreferences.getInstance();
    final data = <String, dynamic>{
      'exportedAt': DateTime.now().toIso8601String(),
      'version': 1,
    };
    for (final key in _keys) {
      data[key] = prefs.getStringList(key) ?? [];
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      '${dir.path}/dps_erp_backup_${DateTime.now().millisecondsSinceEpoch}.json',
    );
    await file.writeAsString(jsonEncode(data));
    return file;
  }

  Future<void> importBackup(File file) async {
    final content = await file.readAsString();
    final data = jsonDecode(content) as Map<String, dynamic>;
    final prefs = await SharedPreferences.getInstance();

    for (final key in _keys) {
      if (data.containsKey(key)) {
        final list = List<String>.from(data[key] as List);
        await prefs.setStringList(key, list);
      }
    }
  }

  Future<void> wipeAllData() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in _keys) {
      await prefs.remove(key);
    }
    await prefs.remove(AppConstants.prefsInvoiceCounterKey);
    await prefs.remove(AppConstants.prefsSessionKey);
  }
}
