import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:genauth/services/audit_log_service.dart';

class AndroidAutofillTelemetryService {
  static const MethodChannel _channel = MethodChannel('genauth/autofill_sync');

  static Future<void> flushPendingTelemetry() async {
    if (!Platform.isAndroid) return;

    String? raw;
    try {
      raw = await _channel.invokeMethod<String>('drainTelemetry');
    } catch (_) {
      return;
    }

    if (raw == null || raw.isEmpty) return;

    List<dynamic> events;
    try {
      events = jsonDecode(raw) as List<dynamic>;
    } catch (_) {
      return;
    }

    for (final item in events) {
      if (item is! Map<String, dynamic>) continue;

      final action = item['action'] as String?;
      if (action == null || action.isEmpty) continue;

      final status = (item['status'] as String?) ?? 'success';
      final detail = item['detail'] as String?;

      Map<String, Object?>? metadata;
      final rawMetadata = item['metadata'];
      if (rawMetadata is Map<String, dynamic>) {
        metadata = rawMetadata.map(
          (key, value) => MapEntry(key, value as Object?),
        );
      }

      await AuditLogService.instance.log(
        action,
        status: status,
        detail: detail,
        metadata: metadata,
      );
    }
  }
}
