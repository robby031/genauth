import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:genauth/models/otp_account.dart';
import 'package:genauth/services/audit_log_service.dart';
import 'package:genauth/services/google_auth_migration_service.dart';

class StorageService {
  static final StorageService instance = StorageService._internal();
  StorageService._internal();

  factory StorageService() => instance;

  static const _key = 'genauth_accounts';
  static const _onboardingKey = 'genauth_onboarding_done';
  static const _pinHashKey = 'genauth_pin_hash';
  static const _pinSaltKey = 'genauth_pin_salt';
  static const _panicPinHashKey = 'genauth_panic_pin_hash';
  static const _panicPinSaltKey = 'genauth_panic_pin_salt';
  static const _panicTriggeredKey = 'genauth_panic_triggered';
  static const _googleProfileKey = 'genauth_google_profile';
  static const _autoBackupEnabledKey = 'genauth_auto_backup_enabled';
  static const _autoBackupIntervalKey = 'genauth_auto_backup_interval';
  static const _autoBackupPasswordKey = 'genauth_auto_backup_password';
  static const _autoBackupLastRunAtKey = 'genauth_auto_backup_last_run_at';
  static const _preferredLocaleKey = 'genauth_preferred_locale';

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
      synchronizable: true,
    ),
  );

  Future<List<OtpAccount>> loadAccounts() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.isEmpty) return [];
    return OtpAccount.listFromJson(raw);
  }

  Future<void> saveAccounts(List<OtpAccount> accounts) async {
    await _storage.write(key: _key, value: OtpAccount.listToJson(accounts));
  }

  Future<void> addAccount(OtpAccount account) async {
    final list = await loadAccounts();
    list.add(account);
    await saveAccounts(list);
    await AuditLogService.instance.log(
      'account_added',
      metadata: {
        'accountId': account.id,
        'issuer': account.issuer,
        'label': account.label,
        'isHotp': account.isHotp,
        'period': account.period,
      },
    );
  }

  Future<int> addAccountsUnique(List<OtpAccount> accounts) async {
    if (accounts.isEmpty) return 0;

    final list = await loadAccounts();
    final existing = list.map(GoogleAuthMigrationService.fingerprint).toSet();
    var importedCount = 0;

    for (final account in accounts) {
      final fingerprint = GoogleAuthMigrationService.fingerprint(account);
      if (existing.add(fingerprint)) {
        list.add(account);
        importedCount++;
      }
    }

    if (importedCount > 0) {
      await saveAccounts(list);
    }

    await AuditLogService.instance.log(
      'accounts_imported',
      metadata: {'requested': accounts.length, 'imported': importedCount},
    );

    return importedCount;
  }

  Future<void> updateAccount(OtpAccount account) async {
    final list = await loadAccounts();
    final idx = list.indexWhere((a) => a.id == account.id);
    if (idx >= 0) {
      list[idx] = account;
      await saveAccounts(list);
    }
  }

  Future<void> deleteAccount(String id) async {
    final list = await loadAccounts();
    list.removeWhere((a) => a.id == id);
    await saveAccounts(list);
    await AuditLogService.instance.log(
      'account_deleted',
      metadata: {'accountId': id},
    );
  }

  Future<bool> hasPin() async =>
      (await _storage.read(key: _pinHashKey)) != null;

  Future<void> savePin(String pin) async {
    final salt = List.generate(16, (_) => Random.secure().nextInt(256));
    final hash = await _hashPin(pin, salt);
    await _storage.write(key: _pinHashKey, value: base64Encode(hash));
    await _storage.write(key: _pinSaltKey, value: base64Encode(salt));
    await AuditLogService.instance.log('pin_set');
  }

  Future<bool> verifyPin(String pin) async {
    final storedHash = await _storage.read(key: _pinHashKey);
    final storedSalt = await _storage.read(key: _pinSaltKey);
    if (storedHash == null || storedSalt == null) return false;
    final hash = await _hashPin(pin, base64Decode(storedSalt));
    return base64Encode(hash) == storedHash;
  }

  Future<void> clearPin() async {
    await _storage.delete(key: _pinHashKey);
    await _storage.delete(key: _pinSaltKey);
    await AuditLogService.instance.log('pin_removed');
  }

  Future<bool> hasPanicPin() async =>
      (await _storage.read(key: _panicPinHashKey)) != null;

  Future<void> savePanicPin(String pin) async {
    final salt = List.generate(16, (_) => Random.secure().nextInt(256));
    final hash = await _hashPin(pin, salt);
    await _storage.write(key: _panicPinHashKey, value: base64Encode(hash));
    await _storage.write(key: _panicPinSaltKey, value: base64Encode(salt));
    await AuditLogService.instance.log('panic_pin_set');
  }

  Future<bool> verifyPanicPin(String pin) async {
    final storedHash = await _storage.read(key: _panicPinHashKey);
    final storedSalt = await _storage.read(key: _panicPinSaltKey);
    if (storedHash == null || storedSalt == null) return false;
    final hash = await _hashPin(pin, base64Decode(storedSalt));
    return base64Encode(hash) == storedHash;
  }

  Future<void> clearPanicPin() async {
    await _storage.delete(key: _panicPinHashKey);
    await _storage.delete(key: _panicPinSaltKey);
    await AuditLogService.instance.log('panic_pin_removed');
  }

  Future<bool> isPanicTriggered() async {
    final raw = await _storage.read(key: _panicTriggeredKey);
    return raw == 'true';
  }

  Future<void> triggerPanicDestruct() async {
    await AuditLogService.instance.log(
      'panic_destruct_triggered',
      status: 'critical',
      detail: 'All local OTP data was wiped by panic PIN trigger.',
    );
    await _storage.delete(key: _key);
    await clearPin();
    await clearPanicPin();
    await _storage.write(key: _panicTriggeredKey, value: 'true');
  }

  static Future<List<int>> _hashPin(String pin, List<int> salt) async {
    final hash = await Sha256().hash([...utf8.encode(pin), ...salt]);
    return hash.bytes;
  }

  Future<bool> isOnboardingCompleted() async {
    final raw = await _storage.read(key: _onboardingKey);
    return raw == 'true';
  }

  Future<void> setOnboardingCompleted(bool done) async {
    await _storage.write(key: _onboardingKey, value: done.toString());
  }

  Future<void> saveGoogleProfile({
    required String email,
    String? displayName,
    String? photoUrl,
    String? googleId,
  }) async {
    final payload = jsonEncode({
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'googleId': googleId,
    });
    await _storage.write(key: _googleProfileKey, value: payload);
  }

  Future<GoogleProfile?> getGoogleProfile() async {
    final raw = await _storage.read(key: _googleProfileKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final email = map['email'] as String?;
      if (email == null || email.isEmpty) return null;
      return GoogleProfile(
        email: email,
        displayName: map['displayName'] as String?,
        photoUrl: map['photoUrl'] as String?,
        googleId: map['googleId'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  Future<bool> hasGoogleProfile() async => (await getGoogleProfile()) != null;

  Future<void> clearGoogleProfile() async {
    await _storage.delete(key: _googleProfileKey);
  }

  Future<bool> isAutoBackupEnabled() async {
    final raw = await _storage.read(key: _autoBackupEnabledKey);
    return raw == 'true';
  }

  Future<void> setAutoBackupEnabled(bool enabled) async {
    await _storage.write(key: _autoBackupEnabledKey, value: enabled.toString());
  }

  Future<String> getAutoBackupInterval() async {
    return (await _storage.read(key: _autoBackupIntervalKey)) ?? 'daily';
  }

  Future<void> setAutoBackupInterval(String interval) async {
    await _storage.write(key: _autoBackupIntervalKey, value: interval);
  }

  Future<String?> getAutoBackupPassword() async {
    return _storage.read(key: _autoBackupPasswordKey);
  }

  Future<void> setAutoBackupPassword(String password) async {
    await _storage.write(key: _autoBackupPasswordKey, value: password);
  }

  Future<void> clearAutoBackupPassword() async {
    await _storage.delete(key: _autoBackupPasswordKey);
  }

  Future<DateTime?> getAutoBackupLastRunAt() async {
    final raw = await _storage.read(key: _autoBackupLastRunAtKey);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> setAutoBackupLastRunAt(DateTime when) async {
    await _storage.write(
      key: _autoBackupLastRunAtKey,
      value: when.toUtc().toIso8601String(),
    );
  }

  Future<String?> getPreferredLocaleCode() async {
    final raw = await _storage.read(key: _preferredLocaleKey);
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }

  Future<void> setPreferredLocaleCode(String languageCode) async {
    await _storage.write(key: _preferredLocaleKey, value: languageCode);
  }
}

class GoogleProfile {
  const GoogleProfile({
    required this.email,
    this.displayName,
    this.photoUrl,
    this.googleId,
  });

  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? googleId;
}

class AutoBackupSettings {
  const AutoBackupSettings({
    required this.enabled,
    required this.interval,
    required this.password,
    required this.lastRunAt,
  });

  final bool enabled;
  final String interval;
  final String? password;
  final DateTime? lastRunAt;
}
