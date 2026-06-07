import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:genauth/services/backup_service.dart';
import 'package:genauth/services/storage_service.dart';
import 'package:genauth/utils/l10n_extensions.dart';
import 'package:genauth/screens/add_account_screen.dart';
import 'package:genauth/screens/google_auth_export_screen.dart';

class BackupScreen extends StatelessWidget {
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.backupAndRestore)),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _GoogleAuthMigrationCard(),
            SizedBox(height: 20),
            _ExportCard(),
            SizedBox(height: 20),
            _ImportCard(),
          ],
        ),
      ),
    );
  }
}

class _GoogleAuthMigrationCard extends StatefulWidget {
  const _GoogleAuthMigrationCard();

  @override
  State<_GoogleAuthMigrationCard> createState() =>
      _GoogleAuthMigrationCardState();
}

class _GoogleAuthMigrationCardState extends State<_GoogleAuthMigrationCard> {
  bool _loading = false;

  Future<void> _openImport() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddAccountScreen(importMode: true),
      ),
    );
  }

  Future<void> _openExport() async {
    setState(() => _loading = true);
    try {
      final accounts = await StorageService().loadAccounts();
      if (!mounted) return;
      if (accounts.isEmpty) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(context.l10n.googleAuthNoAccounts),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GoogleAuthExportScreen(accounts: accounts),
        ),
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

class _ExportCard extends StatefulWidget {
  const _ExportCard();

  @override
  State<_ExportCard> createState() => _ExportCardState();
}

class _ExportCardState extends State<_ExportCard> {
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

    try {
      final accounts = await StorageService().loadAccounts();
      if (!mounted) return;
      if (accounts.isEmpty) {
        _showSnack(context.l10n.backupNoAccounts);
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
        await Share.shareXFiles([
          XFile(file.path, mimeType: 'application/octet-stream'),
        ], subject: context.l10n.backupShareSubject);
      } catch (_) {
        // share sheet unavailable — user can still grab the file from Files.app
      }

      if (!mounted) return;
      _formKey.currentState!.reset();
      _pwCtrl.clear();
      _confirmCtrl.clear();
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
                    context.l10n.backupSavedPath(name),
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
      if (mounted) _showSnack(context.l10n.backupExportFailed(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentMaterialBanner()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
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

class _ImportCard extends StatefulWidget {
  const _ImportCard();

  @override
  State<_ImportCard> createState() => _ImportCardState();
}

class _ImportCardState extends State<_ImportCard> {
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
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    setState(() {
      _pickedFileName = file.name;
      _pickedBytes = file.bytes;
    });
  }

  Future<void> _restore() async {
    final l10n = context.l10n;
    if (_pickedBytes == null) {
      _showSnack(l10n.backupChooseFile);
      return;
    }
    if (_pwCtrl.text.isEmpty) {
      _showSnack(l10n.backupPassword);
      return;
    }

    setState(() => _loading = true);

    try {
      final imported = await BackupService.import(_pickedBytes!, _pwCtrl.text);

      if (!mounted) return;
      final action = await _askMergeOrReplace(imported.length);
      if (action == null || !mounted) return;

      final storage = StorageService();
      if (action == _RestoreAction.replace) {
        await storage.saveAccounts(imported);
      } else {
        final existing = await storage.loadAccounts();
        final existingIds = existing.map((a) => a.id).toSet();
        final merged = [
          ...existing,
          ...imported.where((a) => !existingIds.contains(a.id)),
        ];
        await storage.saveAccounts(merged);
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
      if (mounted) _showSnack(context.l10n.backupInvalidFile(e.message));
    } catch (_) {
      if (mounted) _showSnack(context.l10n.backupWrongPassword);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<_RestoreAction?> _askMergeOrReplace(int count) {
    final l10n = context.l10n;
    return showDialog<_RestoreAction>(
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
            onPressed: () => Navigator.pop(context, _RestoreAction.merge),
            child: Text(l10n.backupMerge),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, _RestoreAction.replace),
            child: Text(l10n.backupReplace),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentMaterialBanner()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

enum _RestoreAction { replace, merge }
