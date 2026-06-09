import 'dart:io';

import 'package:flutter/services.dart';
import 'package:genauth/models/otp_account.dart';

class AndroidAutofillSyncService {
  static const MethodChannel _channel = MethodChannel('genauth/autofill_sync');

  static Future<void> syncAccounts(List<OtpAccount> accounts) async {
    if (!Platform.isAndroid) return;

    final payload = accounts
        .map(
          (account) => {
            'id': account.id,
            'issuer': account.issuer,
            'label': account.label,
            'tags': account.tags,
            'secretB32': account.secretB32,
            'algorithm': account.algorithm,
            'digits': account.digits,
            'period': account.period,
            'counter': account.counter,
            'isHotp': account.isHotp,
          },
        )
        .toList(growable: false);

    try {
      await _channel.invokeMethod<void>('syncAccounts', {'accounts': payload});
    } catch (_) {}
  }

  static Future<void> clearAccounts() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('clearAccounts');
    } catch (_) {}
  }
}
