import 'package:genauth/services/audit_log_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final auditLogProvider = Provider<AuditLogService>((ref) {
  return AuditLogService.instance;
});
