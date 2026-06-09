import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genauth/providers/audit_log_provider.dart';
import 'package:genauth/services/storage_service.dart';
import 'package:genauth/utils/l10n_extensions.dart';
import 'package:genauth/screens/add_account/add_account_screen.dart';
import 'package:genauth/screens/google_export/google_auth_export_screen.dart';
import 'package:genauth/widgets/snack_message.dart';

class GoogleAuthMigration extends ConsumerStatefulWidget {
  const GoogleAuthMigration({super.key});

  @override
  ConsumerState<GoogleAuthMigration> createState() =>
      _GoogleAuthMigrationState();
}

class _GoogleAuthMigrationState extends ConsumerState<GoogleAuthMigration> {
  bool _loading = false;

  Future<void> _openImport() async {
    final audit = ref.read(auditLogProvider);
    await audit.log('google_auth_import_opened');
    if (!mounted) return;
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddAccountScreen(importMode: true),
      ),
    );
  }

  Future<void> _openExport() async {
    setState(() => _loading = true);
    final audit = ref.read(auditLogProvider);
    await audit.log('google_auth_export_attempt');
    try {
      final accounts = await StorageService().loadAccounts();
      if (!mounted) return;
      if (accounts.isEmpty) {
        await audit.log(
          'google_auth_export_blocked',
          status: 'failed',
          detail: 'no_accounts',
        );
        if (!mounted) return;
        SnackMessage.show(
          context,
          context.l10n.googleAuthNoAccounts,
          icon: Icons.warning_amber_outlined,
          backgroundColor: Colors.orange.shade600,
        );
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GoogleAuthExportScreen(accounts: accounts),
        ),
      );
      await audit.log(
        'google_auth_export_opened',
        metadata: {'accountCount': accounts.length},
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
                Icon(Icons.qr_code_2_outlined, color: scheme.primary),
                const SizedBox(width: 10),
                Text(
                  l10n.googleAuthSectionTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l10n.googleAuthSectionDesc,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.outline),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _loading ? null : _openImport,
              icon: const Icon(Icons.download_rounded),
              label: Text(l10n.googleAuthImportAction),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _loading ? null : _openExport,
              icon: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.qr_code_rounded),
              label: Text(l10n.googleAuthExportAction),
            ),
          ],
        ),
      ),
    );
  }
}
