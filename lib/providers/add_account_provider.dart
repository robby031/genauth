import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genauth/models/otp_account.dart';
import 'package:genauth/services/audit_log_service.dart';
import 'package:genauth/services/google_auth_migration_service.dart';
import 'package:genauth/services/otp_service.dart';
import 'package:genauth/services/storage_service.dart';

final addAccountStorageServiceProvider = Provider<StorageService>((ref) {
  return StorageService.instance;
});

final googleAuthMigrationServiceProvider = Provider<GoogleAuthMigrationService>(
  (ref) {
    return GoogleAuthMigrationService();
  },
);

final addAccountProvider =
    AutoDisposeNotifierProvider<AddAccountNotifier, AddAccountState>(
      AddAccountNotifier.new,
    );

class AddAccountState {
  const AddAccountState({this.saving = false});

  final bool saving;

  AddAccountState copyWith({bool? saving}) {
    return AddAccountState(saving: saving ?? this.saving);
  }
}

class AddAccountNotifier extends AutoDisposeNotifier<AddAccountState> {
  @override
  AddAccountState build() {
    return const AddAccountState();
  }

  Future<int> saveFromQrCode(String code) async {
    final migration = ref.read(googleAuthMigrationServiceProvider);
    final storage = ref.read(addAccountStorageServiceProvider);

    final accounts = await migration.decodeAccounts(code);
    final imported = await storage.addAccountsUnique(accounts);
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
    if (state.saving) return;

    state = state.copyWith(saving: true);

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

      await ref.read(addAccountStorageServiceProvider).addAccount(account);
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
      state = state.copyWith(saving: false);
    }
  }

  Future<String> generateSecret() {
    return OtpService.generateSecret();
  }
}
