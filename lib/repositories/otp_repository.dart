import 'dart:async';
import '../models/otp_account.dart';
import '../services/storage_service.dart';
import '../services/otp_service.dart';

class OtpRepository {
  final StorageService _storage;
  OtpRepository(this._storage);

  Future<Map<String, dynamic>> hotpIncrement(OtpAccount account) async {
    final updated = account.copyWith(counter: account.counter + 1);
    await _storage.updateAccount(updated);
    final code = await OtpService.generateCode(updated);

    return {'account': updated, 'code': code};
  }
}
