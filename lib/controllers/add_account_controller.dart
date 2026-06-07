import 'package:flutter/foundation.dart';
import '../models/otp_account.dart';
import '../services/otp_service.dart';
import '../services/storage_service.dart';

class AddAccountController extends ChangeNotifier {
  AddAccountController({required this._storage});

  final StorageService _storage;

  bool _saving = false;
  bool get saving => _saving;

  Future<void> saveFromQrCode(String code) async {
    final account = OtpAccount.fromUri(code);
    await _storage.addAccount(account);
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
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<String> generateSecret() => OtpService.generateSecret();
}
