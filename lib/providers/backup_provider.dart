import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genauth/services/auto_backup_service.dart';
import 'package:genauth/services/storage_service.dart';

final backupStorageServiceProvider = Provider<StorageService>((ref) {
  return StorageService.instance;
});

final backupAutoBackupServiceProvider = Provider<AutoBackupService>((ref) {
  return AutoBackupService.instance;
});
