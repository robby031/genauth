import 'dart:convert';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/otp_account.dart';
import 'google_auth_migration_service.dart';

class StorageService {
  static final StorageService instance = StorageService._internal();
  StorageService._internal();

  factory StorageService() => instance;

  static const _key = 'genauth_accounts';
  static const _onboardingKey = 'genauth_onboarding_done';
  static const _pinHashKey = 'genauth_pin_hash';
  static const _pinSaltKey = 'genauth_pin_salt';

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
