import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:genauth/services/audit_log_service.dart';
import 'package:genauth/services/storage_service.dart';
import 'package:genauth/screens/pin_screen.dart';
import 'package:genauth/utils/l10n_extensions.dart';
import 'package:genauth/widgets/snack_message.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  late Future<List<Map<String, Object?>>> _future;

  @override
  void initState() {
    super.initState();
    AuditLogService.instance.log('audit_log_opened');
    _future = AuditLogService.instance.recent();
  }

  Future<void> _reload() async {
    setState(() {
      _future = AuditLogService.instance.recent();
    });
  }

  Future<void> _clearAll() async {
    final hasPin = await StorageService.instance.hasPin();
    if (!mounted) return;
    if (!hasPin) {
      SnackMessage.show(
        context,
        context.l10n.auditLogPinRequired,
        icon: Icons.warning_amber_outlined,
        backgroundColor: Colors.orange.shade600,
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.l10n.auditLogClearConfirmTitle),
        content: Text(context.l10n.auditLogClearConfirmDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );

    if (ok != true) return;
    if (!mounted) return;
    final pinVerified = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const PinScreen(mode: PinMode.verify)),
    );
    if (!mounted || pinVerified != true) return;

    await AuditLogService.instance.clearAll();
    await _reload();
    if (!mounted) return;
    SnackMessage.show(
      context,
      context.l10n.auditLogCleared,
      icon: Icons.check_circle_outline,
      backgroundColor: Colors.green.shade600,
    );
  }

  String _prettyAction(String action) {
    final words = action.split('_').where((e) => e.isNotEmpty).toList();
    if (words.isEmpty) return action;
    return words
        .map((w) => w.substring(0, 1).toUpperCase() + w.substring(1))
        .join(' ');
  }

  String _formatTime(Object? millis) {
    final value = (millis is int) ? millis : int.tryParse('$millis') ?? 0;
    if (value <= 0) return '-';
    return DateFormat(
      'yyyy-MM-dd HH:mm:ss',
    ).format(DateTime.fromMillisecondsSinceEpoch(value));
  }

  Map<String, Object?>? _metadataMap(Object? raw) {
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw.toString());
      if (decoded is Map<String, dynamic>) {
        return decoded.map((k, v) => MapEntry(k, v as Object?));
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        centerTitle: false,
        title: Text(
          context.l10n.auditLogTitle,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          IconButton(
            tooltip: context.l10n.auditLogClearAll,
            onPressed: _clearAll,
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, Object?>>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final logs = snapshot.data!;
          if (logs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  context.l10n.auditLogEmpty,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
              itemCount: logs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final row = logs[i];
                final action = (row['action'] ?? '').toString();
                final status = (row['status'] ?? '').toString();
                final detail = row['detail']?.toString();
                final metadata = _metadataMap(row['metadata']);

                final statusColor = switch (status) {
                  'failed' => scheme.error,
                  'critical' => Colors.red.shade700,
                  _ => scheme.primary,
                };

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _prettyAction(action),
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatTime(row['created_at']),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      if (detail != null && detail.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${context.l10n.auditLogDetail}: $detail',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      if (metadata != null && metadata.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${context.l10n.auditLogMetadata}:',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          const JsonEncoder.withIndent('  ').convert(metadata),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontFamily: 'monospace',
                                color: scheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
