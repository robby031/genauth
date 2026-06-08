import 'package:genauth/services/audit_log_service.dart';
import 'package:genauth/services/backup_service.dart';
import 'package:genauth/services/google_account_service.dart';
import 'package:genauth/services/storage_service.dart';

class AutoBackupService {
  AutoBackupService._();

  static final AutoBackupService instance = AutoBackupService._();

  bool _running = false;

  Future<AutoBackupSettings> loadSettings() async {
    final storage = StorageService.instance;
    return AutoBackupSettings(
      enabled: await storage.isAutoBackupEnabled(),
      interval: await storage.getAutoBackupInterval(),
      password: await storage.getAutoBackupPassword(),
      lastRunAt: await storage.getAutoBackupLastRunAt(),
    );
  }

  Future<void> saveSettings({
    required bool enabled,
    required String interval,
    required String password,
  }) async {
    final storage = StorageService.instance;
    await storage.setAutoBackupEnabled(enabled);
    await storage.setAutoBackupInterval(interval);
    await storage.setAutoBackupPassword(password);
  }

  Future<void> disable() async {
    final storage = StorageService.instance;
    await storage.setAutoBackupEnabled(false);
    await storage.clearAutoBackupPassword();
  }

  Future<void> maybeRun({required String reason}) async {
    if (_running) return;
    _running = true;
    try {
      final settings = await loadSettings();
      if (!settings.enabled) return;
      final password = settings.password;
      if (password == null || password.length < 8) return;
      if (!GoogleAccountService.instance.isSignedIn) return;

      final now = DateTime.now().toUtc();
      final gap = settings.interval == 'weekly'
          ? const Duration(days: 7)
          : const Duration(days: 1);
      final lastRunAt = settings.lastRunAt?.toUtc();
      if (lastRunAt != null && now.difference(lastRunAt) < gap) return;

      final accounts = await StorageService.instance.loadAccounts();
      if (accounts.isEmpty) return;

      await AuditLogService.instance.log(
        'auto_backup_attempt',
        metadata: {'reason': reason, 'interval': settings.interval},
      );

      final bytes = await BackupService.export(accounts, password);
      final stamp =
          '${now.year}${_p2(now.month)}${_p2(now.day)}-${_p2(now.hour)}${_p2(now.minute)}${_p2(now.second)}';
      final fileName = 'genauth-auto-backup-$stamp.genauth';
      final uploaded = await GoogleAccountService.instance.uploadBackup(
        bytes: bytes,
        fileName: fileName,
      );

      await StorageService.instance.setAutoBackupLastRunAt(now);
      await AuditLogService.instance.log(
        'auto_backup_success',
        metadata: {
          'reason': reason,
          'fileName': uploaded.name,
          'fileId': uploaded.id,
          'accountCount': accounts.length,
        },
      );
    } catch (e) {
      await AuditLogService.instance.log(
        'auto_backup_failed',
        status: 'failed',
        detail: e.toString(),
        metadata: {'reason': reason},
      );
    } finally {
      _running = false;
    }
  }
}

String _p2(int n) => n.toString().padLeft(2, '0');
