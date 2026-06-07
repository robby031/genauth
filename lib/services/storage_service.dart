import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/otp_account.dart';

class StorageService {
  static final StorageService instance = StorageService._internal();
  StorageService._internal();

  factory StorageService() => instance;

  static const _key = 'genauth_accounts';

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
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
}
