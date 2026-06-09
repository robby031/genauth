import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genauth/providers/audit_log_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:genauth/services/backup_service.dart';
import 'package:genauth/services/storage_service.dart';
import 'package:genauth/utils/l10n_extensions.dart';
import 'package:genauth/widgets/snack_message.dart';

class Export extends ConsumerStatefulWidget {
  const Export({super.key});

  @override
  ConsumerState<Export> createState() => _ExportState();
}

class _ExportState extends ConsumerState<Export> {
  final _formKey = GlobalKey<FormState>();
  final _pwCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _loading = false;

  @override
  void dispose() {
    _pwCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _export() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final audit = ref.read(auditLogProvider);
    await audit.log('backup_export_attempt');

    try {
      final accounts = await StorageService().loadAccounts();
      if (!mounted) return;
      if (accounts.isEmpty) {
        await audit.log(
          'backup_export_blocked',
          status: 'failed',
          detail: 'no_accounts',
        );
        if (!mounted) return;
        SnackMessage.show(
          context,
          context.l10n.backupNoAccounts,
          icon: Icons.warning_amber_outlined,
          backgroundColor: Colors.orange.shade600,
        );
        return;
      }

      final bytes = await BackupService.export(accounts, _pwCtrl.text);

      final dir = await getApplicationDocumentsDirectory();
      final now = DateTime.now().toLocal();
      final name =
          'genauth-backup-${now.year}-${_p(now.month)}-${_p(now.day)}.genauth';
      final file = File('${dir.path}/$name');
      await file.writeAsBytes(bytes);

      if (!mounted) return;

      try {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path, mimeType: 'application/octet-stream')],
            subject: context.l10n.backupShareSubject,
          ),
        );
      } catch (_) {
        // share sheet unavailable — user can still grab the file from Files.app
      }

      if (!mounted) return;
      _formKey.currentState!.reset();
      _pwCtrl.clear();
      _confirmCtrl.clear();
      await audit.log(
        'backup_export_success',
        metadata: {'fileName': name, 'accountCount': accounts.length},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentMaterialBanner()
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
                    context.l10n.backupSavedFile(name),
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
    } catch (e) {
      await audit.log(
        'backup_export_failed',
        status: 'failed',
        detail: e.toString(),
      );
      if (!mounted) return;
      SnackMessage.show(
        context,
        context.l10n.backupExportFailed(e.toString()),
        icon: Icons.error_outline,
        backgroundColor: Colors.red.shade600,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _p(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.upload_file, color: scheme.primary),
                  const SizedBox(width: 10),
                  Text(
                    l10n.backupExportTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                l10n.backupExportDesc,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.outline),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pwCtrl,
                obscureText: _obscure1,
                decoration: InputDecoration(
                  labelText: l10n.backupPassword,
                  labelStyle: TextStyle(fontSize: 12),
                  isDense: true,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure1 ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setState(() => _obscure1 = !_obscure1),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.length < 8) ? l10n.backupPasswordMin : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmCtrl,
                obscureText: _obscure2,
                decoration: InputDecoration(
                  labelText: l10n.backupPasswordConfirm,
                  labelStyle: TextStyle(fontSize: 12),
                  isDense: true,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure2 ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setState(() => _obscure2 = !_obscure2),
                  ),
                ),
                validator: (v) =>
                    v != _pwCtrl.text ? l10n.backupPasswordMismatch : null,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _loading ? null : _export,
                icon: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.share),
                label: Text(
                  _loading ? l10n.backupEncrypting : l10n.backupExportShare,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
