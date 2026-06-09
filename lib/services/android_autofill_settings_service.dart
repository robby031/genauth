import 'dart:io';

import 'package:flutter/services.dart';

class AndroidAutofillSettingsService {
  static const MethodChannel _channel = MethodChannel(
    'genauth/autofill_settings',
  );

  static Future<bool> openAutofillSettings() async {
    if (!Platform.isAndroid) return false;

    try {
      final ok = await _channel.invokeMethod<bool>('openAutofillSettings');
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }
}
