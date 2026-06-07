import 'dart:async';

import 'package:flutter/services.dart';
import 'package:genauth/services/otp_service.dart';

class ClipboardSecurityService {
  ClipboardSecurityService._();

  static final ClipboardSecurityService instance = ClipboardSecurityService._();

  Timer? _clearTimer;
  int _scheduleId = 0;

  Future<void> copyOtp({
    required String code,
    required int period,
    required bool isHotp,
  }) async {
    await Clipboard.setData(ClipboardData(text: code));

    _clearTimer?.cancel();
    if (isHotp) {
      return;
    }

    final currentId = ++_scheduleId;
    final secondsUntilExpiry = OtpService.remainingSeconds(period);
    _clearTimer = Timer(Duration(seconds: secondsUntilExpiry), () async {
      if (currentId != _scheduleId) {
        return;
      }

      final data = await Clipboard.getData('text/plain');
      if (data?.text == code) {
        await Clipboard.setData(const ClipboardData(text: ''));
      }
    });
  }

  void dispose() {
    _clearTimer?.cancel();
  }
}
