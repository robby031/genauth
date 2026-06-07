import 'package:flutter/foundation.dart';
import 'package:genauth/models/otp_account.dart';
import 'package:genauth/services/audit_log_service.dart';
import 'package:genauth/services/google_auth_migration_service.dart';
import 'package:genauth/services/otp_service.dart';
import 'package:genauth/services/storage_service.dart';

class AddAccountController extends ChangeNotifier {
  AddAccountController({required this._storage});

  final StorageService _storage;
  final GoogleAuthMigrationService _migration = GoogleAuthMigrationService();

  bool _saving = false;
  bool get saving => _saving;

  Future<int> saveFromQrCode(String code) async {
    final accounts = await _migration.decodeAccounts(code);
    final imported = await _storage.addAccountsUnique(accounts);
    await AuditLogService.instance.log(
      'account_import_qr',
      metadata: {'decoded': accounts.length, 'imported': imported},
    );
    return imported;
  }

  Future<void> saveManualAccount({
    required String label,
    required String issuer,
    required String secret,
    required String algorithm,
    required int digits,
    required int period,
    required bool isHotp,
  }) async {
    if (_saving) return;

    _saving = true;
    notifyListeners();

    try {
      final account = OtpAccount(
        id: OtpAccount.newId(),
        label: label.trim(),
        issuer: issuer.trim(),
        secretB32: secret.trim().toUpperCase().replaceAll(' ', ''),
        algorithm: algorithm,
        digits: digits,
        period: period,
        isHotp: isHotp,
      );

      await _storage.addAccount(account);
      await AuditLogService.instance.log(
        'account_add_manual',
        metadata: {
          'accountId': account.id,
          'issuer': account.issuer,
          'label': account.label,
          'isHotp': account.isHotp,
          'period': account.period,
        },
      );
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<String> generateSecret() => OtpService.generateSecret();
}
