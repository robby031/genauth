import 'dart:async';
import 'package:genauth/models/otp_account.dart';
import 'package:genauth/services/storage_service.dart';
import 'package:genauth/services/otp_service.dart';

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