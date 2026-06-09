import 'dart:async';

import 'dart:typed_data';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genauth/services/backup_service.dart';
import 'package:genauth/services/storage_service.dart';
import 'package:genauth/utils/l10n_extensions.dart';
import 'package:genauth/widgets/snack_message.dart';
import 'package:genauth/providers/audit_log_provider.dart';

enum RestoreAction { replace, merge }

final importStorageServiceProvider = Provider<StorageService>((ref) {
  return StorageService.instance;
});

class Import extends ConsumerStatefulWidget {
  const Import({super.key});

  @override
  ConsumerState<Import> createState() => _ImportState();
}

class _ImportState extends ConsumerState<Import> {
  final _pwCtrl = TextEditingController();

  bool _obscure = true;
  bool _loading = false;
  String? _pickedFileName;
  Uint8List? _pickedBytes;

  @override
  void dispose() {
    _pwCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'GenAuth Backup',
          extensions: ['genauth', 'json', 'txt'],
        ),
      ],
    );

    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _pickedFileName = file.name;
      _pickedBytes = bytes;
    });
  }

  Future<void> _restore() async {
    final l10n = context.l10n;
    final audit = ref.read(auditLogProvider);
    final storage = ref.read(importStorageServiceProvider);

    if (_pickedBytes == null) {
      SnackMessage.show(
        context,
        l10n.backupChooseFile,
        icon: Icons.warning_amber_outlined,
        backgroundColor: Colors.orange.shade600,
      );
      return;
    }
    if (_pwCtrl.text.isEmpty) {
      SnackMessage.show(
        context,
        l10n.backupPassword,
        icon: Icons.warning_amber_outlined,
        backgroundColor: Colors.orange.shade600,
      );
      return;
    }

    setState(() => _loading = true);
    await audit.log('backup_restore_attempt');

    try {
      final imported = await BackupService.import(_pickedBytes!, _pwCtrl.text);

      if (!mounted) return;
      final action = await _askMergeOrReplace(imported.length);
      if (action == null || !mounted) return;

      if (action == RestoreAction.replace) {
        await storage.saveAccounts(imported);
        await audit.log(
          'backup_restore_success',
          metadata: {'mode': 'replace', 'importedCount': imported.length},
        );
      } else {
        final existing = await storage.loadAccounts();
        final existingIds = existing.map((a) => a.id).toSet();
        final merged = [
          ...existing,
          ...imported.where((a) => !existingIds.contains(a.id)),
        ];
        await storage.saveAccounts(merged);
        await audit.log(
          'backup_restore_success',
          metadata: {'mode': 'merge', 'importedCount': imported.length},
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            backgroundColor: Colors.green.shade600,
            duration: const Duration(seconds: 3),
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.backupRestoredSuccess(imported.length),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      setState(() {
        _pickedFileName = null;
        _pickedBytes = null;
        _pwCtrl.clear();
      });
    } on FormatException catch (e) {
      await audit.log(
        'backup_restore_failed',
        status: 'failed',
        detail: e.message,
      );
      if (mounted) {
        SnackMessage.show(
          context,
          context.l10n.backupInvalidFile(e.message),
          icon: Icons.error_outline,
          backgroundColor: Colors.red.shade600,
        );
      }
    } catch (_) {
      await audit.log(
        'backup_restore_failed',
        status: 'failed',
        detail: 'wrong_password_or_corrupted_file',
      );
      if (mounted) {
        SnackMessage.show(
          context,
          context.l10n.backupWrongPassword,
          icon: Icons.error_outline,
          backgroundColor: Colors.red.shade600,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<RestoreAction?> _askMergeOrReplace(int count) {
    final l10n = context.l10n;
    return showDialog<RestoreAction>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.backupRestoreDialogTitle),
        content: Text(l10n.backupRestoreDialogContent(count)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, RestoreAction.merge),
            child: Text(l10n.backupMerge),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, RestoreAction.replace),
            child: Text(l10n.backupReplace),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.download_for_offline, color: scheme.primary),
                const SizedBox(width: 10),
                Text(
                  l10n.backupRestoreTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l10n.backupRestoreDesc,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.outline),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.folder_open),
              label: Text(
                _pickedFileName ?? l10n.backupChooseFile,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _pwCtrl,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: l10n.backupPassword,
                labelStyle: TextStyle(fontSize: 12),
                isDense: true,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: (_loading || _pickedBytes == null) ? null : _restore,
              icon: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.restore),
              label: Text(
                _loading ? l10n.backupDecrypting : l10n.backupRestore,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
