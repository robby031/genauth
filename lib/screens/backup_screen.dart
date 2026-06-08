import 'dart:io';
import 'dart:typed_data';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:genauth/services/audit_log_service.dart';
import 'package:genauth/services/backup_service.dart';
import 'package:genauth/services/google_account_service.dart';
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
            _DriveBackupCard(),
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
    await AuditLogService.instance.log('google_auth_import_opened');
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
    await AuditLogService.instance.log('google_auth_export_attempt');
    try {
      final accounts = await StorageService().loadAccounts();
      if (!mounted) return;
      if (accounts.isEmpty) {
        await AuditLogService.instance.log(
          'google_auth_export_blocked',
          status: 'failed',
          detail: 'no_accounts',
        );
        if (!mounted) return;
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
      await AuditLogService.instance.log(
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
    await AuditLogService.instance.log('backup_export_attempt');

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
      await AuditLogService.instance.log(
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
      await AuditLogService.instance.log(
        'backup_export_failed',
        status: 'failed',
        detail: e.toString(),
      );
      if (!mounted) return;
      _showSnack(context.l10n.backupExportFailed(e.toString()));
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
    if (_pickedBytes == null) {
      _showSnack(l10n.backupChooseFile);
      return;
    }
    if (_pwCtrl.text.isEmpty) {
      _showSnack(l10n.backupPassword);
      return;
    }

    setState(() => _loading = true);
    await AuditLogService.instance.log('backup_restore_attempt');

    try {
      final imported = await BackupService.import(_pickedBytes!, _pwCtrl.text);

      if (!mounted) return;
      final action = await _askMergeOrReplace(imported.length);
      if (action == null || !mounted) return;

      final storage = StorageService();
      if (action == _RestoreAction.replace) {
        await storage.saveAccounts(imported);
        await AuditLogService.instance.log(
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
        await AuditLogService.instance.log(
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
      await AuditLogService.instance.log(
        'backup_restore_failed',
        status: 'failed',
        detail: e.message,
      );
      if (mounted) _showSnack(context.l10n.backupInvalidFile(e.message));
    } catch (_) {
      await AuditLogService.instance.log(
        'backup_restore_failed',
        status: 'failed',
        detail: 'wrong_password_or_corrupted_file',
      );
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

class _DriveBackupCard extends StatefulWidget {
  const _DriveBackupCard();

  @override
  State<_DriveBackupCard> createState() => _DriveBackupCardState();
}

class _DriveBackupCardState extends State<_DriveBackupCard> {
  final _service = GoogleAccountService.instance;
  final _pwCtrl = TextEditingController();
  bool _obscure = true;
  bool _busy = false;

  @override
  void dispose() {
    _pwCtrl.dispose();
    super.dispose();
  }

  void _showSnack(String message, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
          backgroundColor: color,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
  }

  Future<void> _signIn() async {
    setState(() => _busy = true);
    await AuditLogService.instance.log('drive_backup_signin_attempt');
    try {
      await _service.signIn();
      await AuditLogService.instance.log('drive_backup_signin_success');
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        await AuditLogService.instance.log(
          'drive_backup_signin_canceled',
          status: 'failed',
        );
        return;
      }
      await AuditLogService.instance.log(
        'drive_backup_signin_failed',
        status: 'failed',
        detail: e.code.name,
      );
      if (mounted) {
        _showSnack(
          context.l10n.driveBackupSignInFailed(e.description ?? e.code.name),
        );
      }
    } catch (e) {
      await AuditLogService.instance.log(
        'drive_backup_signin_failed',
        status: 'failed',
        detail: e.toString(),
      );
      if (mounted) {
        _showSnack(context.l10n.driveBackupSignInFailed(e.toString()));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    setState(() => _busy = true);
    try {
      await _service.signOut();
      await AuditLogService.instance.log('drive_backup_signout');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _upload() async {
    final l10n = context.l10n;
    if (_pwCtrl.text.length < 8) {
      _showSnack(l10n.backupPasswordMin);
      return;
    }

    setState(() => _busy = true);
    await AuditLogService.instance.log('drive_backup_upload_attempt');
    try {
      final accounts = await StorageService().loadAccounts();
      if (!mounted) return;
      if (accounts.isEmpty) {
        _showSnack(l10n.backupNoAccounts);
        return;
      }

      final bytes = await BackupService.export(accounts, _pwCtrl.text);
      final now = DateTime.now().toUtc();
      final stamp =
          '${now.year}${_p2(now.month)}${_p2(now.day)}-${_p2(now.hour)}${_p2(now.minute)}${_p2(now.second)}';
      final fileName = 'genauth-backup-$stamp.genauth';

      final uploaded = await _service.uploadBackup(
        bytes: bytes,
        fileName: fileName,
      );

      await AuditLogService.instance.log(
        'drive_backup_upload_success',
        metadata: {
          'fileName': uploaded.name,
          'fileId': uploaded.id,
          'accountCount': accounts.length,
        },
      );

      if (!mounted) return;
      _pwCtrl.clear();
      _showSnack(
        l10n.driveBackupUploadSuccess(uploaded.name),
        color: Colors.green.shade600,
      );
    } catch (e) {
      await AuditLogService.instance.log(
        'drive_backup_upload_failed',
        status: 'failed',
        detail: e.toString(),
      );
      if (mounted) {
        _showSnack(context.l10n.driveBackupUploadFailed(e.toString()));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final l10n = context.l10n;
    setState(() => _busy = true);
    try {
      final files = await _service.listBackups();
      if (!mounted) return;

      if (files.isEmpty) {
        _showSnack(l10n.driveBackupEmpty);
        return;
      }

      final picked = await showModalBottomSheet<DriveBackupFile>(
        context: context,
        showDragHandle: true,
        builder: (sheetCtx) => _DriveBackupPickerSheet(files: files),
      );
      if (!mounted || picked == null) return;

      final password = await _promptPassword();
      if (!mounted || password == null) return;

      setState(() => _busy = true);
      await AuditLogService.instance.log(
        'drive_backup_restore_attempt',
        metadata: {'fileId': picked.id, 'fileName': picked.name},
      );

      final bytes = await _service.downloadBackup(picked.id);
      final imported = await BackupService.import(bytes, password);
      if (!mounted) return;

      final action = await _askMergeOrReplace(imported.length);
      if (!mounted || action == null) return;

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

      await AuditLogService.instance.log(
        'drive_backup_restore_success',
        metadata: {
          'mode': action == _RestoreAction.replace ? 'replace' : 'merge',
          'importedCount': imported.length,
          'fileName': picked.name,
        },
      );

      if (!mounted) return;
      _showSnack(
        l10n.backupRestoredSuccess(imported.length),
        color: Colors.green.shade600,
      );
    } catch (e) {
      await AuditLogService.instance.log(
        'drive_backup_restore_failed',
        status: 'failed',
        detail: e.toString(),
      );
      if (mounted) {
        _showSnack(context.l10n.driveBackupRestoreFailed(e.toString()));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _promptPassword() async {
    final ctrl = TextEditingController();
    var obscure = true;
    final l10n = context.l10n;
    final result = await showDialog<String>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: Text(l10n.backupRestore),
              content: TextField(
                controller: ctrl,
                obscureText: obscure,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: l10n.backupPassword,
                  isDense: true,
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setLocal(() => obscure = !obscure),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogCtx, ctrl.text),
                  child: Text(l10n.backupRestore),
                ),
              ],
            );
          },
        );
      },
    );
    ctrl.dispose();
    return result;
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

  String _p2(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ValueListenableBuilder<GoogleSignInAccount?>(
          valueListenable: _service.userNotifier,
          builder: (context, user, _) {
            final signedIn = user != null;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.cloud_outlined, color: scheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.driveBackupTitle,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.driveBackupDesc,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: scheme.outline),
                ),
                const SizedBox(height: 16),
                if (!signedIn)
                  FilledButton.icon(
                    onPressed: _busy ? null : _signIn,
                    icon: _busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.login),
                    label: Text(l10n.driveBackupSignIn),
                  )
                else ...[
                  _SignedInTile(user: user, onSignOut: _busy ? null : _signOut),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _pwCtrl,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: l10n.backupPassword,
                      labelStyle: const TextStyle(fontSize: 12),
                      isDense: true,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _busy ? null : _upload,
                    icon: _busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_upload_outlined),
                    label: Text(
                      _busy
                          ? l10n.driveBackupUploading
                          : l10n.driveBackupUpload,
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _restore,
                    icon: const Icon(Icons.cloud_download_outlined),
                    label: Text(l10n.driveBackupRestore),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SignedInTile extends StatelessWidget {
  const _SignedInTile({required this.user, required this.onSignOut});

  final GoogleSignInAccount user;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final photoUrl = user.photoUrl;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
            child: photoUrl == null
                ? const Icon(Icons.person_outline, size: 18)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName ?? user.email,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  l10n.driveBackupSignedInAs(user.email),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: scheme.outline),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onSignOut,
            child: Text(l10n.driveBackupSignOut),
          ),
        ],
      ),
    );
  }
}

class _DriveBackupPickerSheet extends StatelessWidget {
  const _DriveBackupPickerSheet({required this.files});

  final List<DriveBackupFile> files;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final dateFmt = DateFormat.yMMMd().add_jm();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Text(
                l10n.driveBackupRestore,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: files.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final file = files[i];
                  final modified = file.modifiedTime;
                  final subtitle = modified == null
                      ? null
                      : dateFmt.format(modified.toLocal());
                  return ListTile(
                    leading: Icon(Icons.lock_outlined, color: scheme.primary),
                    title: Text(
                      file.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: subtitle != null ? Text(subtitle) : null,
                    onTap: () => Navigator.pop(context, file),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
