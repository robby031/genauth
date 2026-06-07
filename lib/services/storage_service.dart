import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:genauth/models/otp_account.dart';
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
  }

  Future<bool> hasPin() async =>
      (await _storage.read(key: _pinHashKey)) != null;

  Future<void> savePin(String pin) async {
    final salt = List.generate(16, (_) => Random.secure().nextInt(256));
    final hash = await _hashPin(pin, salt);
    await _storage.write(key: _pinHashKey, value: base64Encode(hash));
    await _storage.write(key: _pinSaltKey, value: base64Encode(salt));
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
  }

  Future<bool> hasPanicPin() async =>
      (await _storage.read(key: _panicPinHashKey)) != null;

  Future<void> savePanicPin(String pin) async {
    final salt = List.generate(16, (_) => Random.secure().nextInt(256));
    final hash = await _hashPin(pin, salt);
    await _storage.write(key: _panicPinHashKey, value: base64Encode(hash));
    await _storage.write(key: _panicPinSaltKey, value: base64Encode(salt));
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
  }

  Future<bool> isPanicTriggered() async {
    final raw = await _storage.read(key: _panicTriggeredKey);
    return raw == 'true';
  }

  Future<void> triggerPanicDestruct() async {
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
}
