import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genauth/providers/backup_provider.dart';
import 'package:genauth/services/google_account_service.dart'
    show DriveBackupFile;
import 'package:genauth/services/backup_service.dart';
import 'package:genauth/utils/l10n_extensions.dart';
import 'package:genauth/widgets/snack_message.dart';
import 'package:genauth/screens/backup/widgets/import.dart';
import 'package:genauth/screens/backup/widgets/drive_picker.dart';
import 'package:genauth/screens/backup/widgets/dialog_pasword.dart';
import 'package:genauth/providers/audit_log_provider.dart';
import 'package:genauth/providers/google_account_provider.dart';

class DriveBackup extends ConsumerStatefulWidget {
  const DriveBackup({super.key});

  @override
  ConsumerState<DriveBackup> createState() => _DriveBackupState();
}

class _DriveBackupState extends ConsumerState<DriveBackup> {
  final _pwCtrl = TextEditingController();
  final _autoPwCtrl = TextEditingController();

  bool _obscure = true;
  bool _autoObscure = true;
  bool _busy = false;
  bool _autoEnabled = false;
  String _autoInterval = 'daily';
  bool _settingsLoaded = false;
  bool _authChecked = false;

  @override
  void initState() {
    super.initState();
    unawaited(_bootstrapDriveCard());
  }

  Future<void> _bootstrapDriveCard() async {
    await Future.wait<void>([_loadAutoBackupSettings(), _prepareGoogleState()]);
    if (!mounted) return;
    setState(() {
      _authChecked = true;
    });
  }

  Future<void> _prepareGoogleState() async {
    final service = ref.read(googleAccountProvider);
    final storage = ref.read(backupStorageServiceProvider);
    final hasStoredProfile = await storage.hasGoogleProfile();
    if (!mounted) return;
    if (!hasStoredProfile) return;
    await service.initialize(restorePreviousSignIn: true);
  }

  @override
  void dispose() {
    _pwCtrl.dispose();
    _autoPwCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAutoBackupSettings() async {
    final autoBackupService = ref.read(backupAutoBackupServiceProvider);
    final settings = await autoBackupService.loadSettings();
    if (!mounted) return;
    _autoPwCtrl.text = settings.password ?? '';
    setState(() {
      _autoEnabled = settings.enabled;
      _autoInterval = settings.interval;
      _settingsLoaded = true;
    });
  }

  Future<void> _signIn() async {
    setState(() => _busy = true);
    final audit = ref.read(auditLogProvider);
    await audit.log('drive_backup_signin_attempt');
    final service = ref.read(googleAccountProvider);
    try {
      await service.signIn();
      await audit.log('drive_backup_signin_success');
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        await audit.log('drive_backup_signin_canceled', status: 'failed');
        return;
      }
      await audit.log(
        'drive_backup_signin_failed',
        status: 'failed',
        detail: e.code.name,
      );
      if (mounted) {
        SnackMessage.show(
          context,
          context.l10n.driveBackupSignInFailed(e.description ?? e.code.name),
          icon: Icons.error_outline,
          backgroundColor: Colors.red.shade600,
        );
      }
    } catch (e) {
      await audit.log(
        'drive_backup_signin_failed',
        status: 'failed',
        detail: e.toString(),
      );
      if (mounted) {
        SnackMessage.show(
          context,
          context.l10n.driveBackupSignInFailed(e.toString()),
          icon: Icons.error_outline,
          backgroundColor: Colors.red.shade600,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _upload() async {
    final l10n = context.l10n;
    if (_pwCtrl.text.length < 8) {
      SnackMessage.show(
        context,
        l10n.backupPasswordMin,
        icon: Icons.warning_amber_outlined,
        backgroundColor: Colors.orange.shade600,
      );
      return;
    }

    setState(() => _busy = true);
    final audit = ref.read(auditLogProvider);
    await audit.log('drive_backup_upload_attempt');
    try {
      final storage = ref.read(backupStorageServiceProvider);
      final accounts = await storage.loadAccounts();
      if (!mounted) return;
      if (accounts.isEmpty) {
        SnackMessage.show(
          context,
          l10n.backupNoAccounts,
          icon: Icons.warning_amber_outlined,
          backgroundColor: Colors.orange.shade600,
        );
        return;
      }

      final bytes = await BackupService.export(accounts, _pwCtrl.text);
      final now = DateTime.now().toUtc();
      final stamp =
          '${now.year}${_p2(now.month)}${_p2(now.day)}-${_p2(now.hour)}${_p2(now.minute)}${_p2(now.second)}';
      final fileName = 'genauth-backup-$stamp.genauth';

      final service = ref.read(googleAccountProvider);
      final uploaded = await service.uploadBackup(
        bytes: bytes,
        fileName: fileName,
      );

      await audit.log(
        'drive_backup_upload_success',
        metadata: {
          'fileName': uploaded.name,
          'fileId': uploaded.id,
          'accountCount': accounts.length,
        },
      );

      if (!mounted) return;
      _pwCtrl.clear();
      SnackMessage.show(
        context,
        l10n.driveBackupUploadSuccess(uploaded.name),
        icon: Icons.check_circle_outline,
        backgroundColor: Colors.green.shade600,
      );
    } catch (e) {
      await audit.log(
        'drive_backup_upload_failed',
        status: 'failed',
        detail: e.toString(),
      );
      if (mounted) {
        SnackMessage.show(
          context,
          context.l10n.driveBackupUploadFailed(e.toString()),
          icon: Icons.error_outline,
          backgroundColor: Colors.red.shade600,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final l10n = context.l10n;
    final service = ref.read(googleAccountProvider);
    final audit = ref.read(auditLogProvider);
    final files = await service.listBackups();

    setState(() => _busy = true);
    try {
      if (!mounted) return;

      if (files.isEmpty) {
        SnackMessage.show(
          context,
          l10n.driveBackupEmpty,
          icon: Icons.warning_amber_outlined,
          backgroundColor: Colors.orange.shade600,
        );
        return;
      }

      final picked = await showModalBottomSheet<DriveBackupFile>(
        context: context,
        showDragHandle: true,
        builder: (sheetCtx) => DriveBackupPickerSheet(files: files),
      );
      if (!mounted || picked == null) return;

      final password = await _promptPassword();
      if (!mounted || password == null) return;

      setState(() => _busy = true);
      await audit.log(
        'drive_backup_restore_attempt',
        metadata: {'fileId': picked.id, 'fileName': picked.name},
      );

      final bytes = await service.downloadBackup(picked.id);
      final imported = await BackupService.import(bytes, password);
      if (!mounted) return;

      final action = await _askMergeOrReplace(imported.length);
      if (!mounted || action == null) return;

      final storage = ref.read(backupStorageServiceProvider);
      if (action == RestoreAction.replace) {
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

      await audit.log(
        'drive_backup_restore_success',
        metadata: {
          'mode': action == RestoreAction.replace ? 'replace' : 'merge',
          'importedCount': imported.length,
          'fileName': picked.name,
        },
      );

      if (!mounted) return;
      SnackMessage.show(
        context,
        l10n.backupRestoredSuccess(imported.length),
        icon: Icons.check_circle_outline,
        backgroundColor: Colors.green.shade600,
      );
    } catch (e) {
      await audit.log(
        'drive_backup_restore_failed',
        status: 'failed',
        detail: e.toString(),
      );
      if (mounted) {
        SnackMessage.show(
          context,
          context.l10n.driveBackupRestoreFailed(e.toString()),
          icon: Icons.error_outline,
          backgroundColor: Colors.red.shade600,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveAutoBackupSettings() async {
    final l10n = context.l10n;
    final autoBackupService = ref.read(backupAutoBackupServiceProvider);

    if (_autoEnabled && _autoPwCtrl.text.length < 8) {
      SnackMessage.show(
        context,
        l10n.driveAutoBackupPasswordMin,
        icon: Icons.warning_amber_outlined,
        backgroundColor: Colors.orange.shade600,
      );
      return;
    }

    setState(() => _busy = true);
    try {
      if (_autoEnabled) {
        await autoBackupService.saveSettings(
          enabled: true,
          interval: _autoInterval,
          password: _autoPwCtrl.text,
        );
        await autoBackupService.maybeRun(reason: 'auto_backup_enabled');
        if (!mounted) return;
        SnackMessage.show(
          context,
          l10n.driveAutoBackupSaved,
          icon: Icons.check_circle_outline,
          backgroundColor: Colors.green.shade600,
        );
      } else {
        await autoBackupService.disable();
        if (!mounted) return;
        SnackMessage.show(
          context,
          l10n.driveAutoBackupDisabled,
          icon: Icons.info_outline,
          backgroundColor: Colors.blueGrey.shade600,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _promptPassword() async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => const PasswordDialog(),
    );
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

  String _p2(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final user = ref.watch(googleAccountUserProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.cloud_outlined, color: scheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.driveBackupTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
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
            if (!_authChecked)
              const Center(child: CircularProgressIndicator())
            else if (user == null)
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
              _SignedInTile(user: user),
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
                  _busy ? l10n.driveBackupUploading : l10n.driveBackupUpload,
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _busy ? null : _restore,
                icon: const Icon(Icons.cloud_download_outlined),
                label: Text(l10n.driveBackupRestore),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                l10n.driveAutoBackupTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.driveAutoBackupDesc,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.outline),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.driveAutoBackupEnable),
                value: _autoEnabled,
                onChanged: !_settingsLoaded || _busy
                    ? null
                    : (value) => setState(() => _autoEnabled = value),
              ),
              DropdownButtonFormField<String>(
                initialValue: _autoInterval,
                decoration: InputDecoration(
                  labelText: l10n.driveAutoBackupInterval,
                  labelStyle: const TextStyle(fontSize: 12),
                  isDense: true,
                ),
                items: [
                  DropdownMenuItem(
                    value: 'daily',
                    child: Text(l10n.driveAutoBackupDaily),
                  ),
                  DropdownMenuItem(
                    value: 'weekly',
                    child: Text(l10n.driveAutoBackupWeekly),
                  ),
                ],
                onChanged: !_autoEnabled || _busy
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => _autoInterval = value);
                        }
                      },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _autoPwCtrl,
                obscureText: _autoObscure,
                enabled: _autoEnabled && !_busy,
                decoration: InputDecoration(
                  labelText: l10n.driveAutoBackupPassword,
                  labelStyle: const TextStyle(fontSize: 12),
                  isDense: true,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _autoObscure ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () =>
                        setState(() => _autoObscure = !_autoObscure),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _busy ? null : _saveAutoBackupSettings,
                icon: const Icon(Icons.schedule_send_outlined),
                label: Text(l10n.done),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SignedInTile extends StatelessWidget {
  const _SignedInTile({required this.user});

  final GoogleSignInAccount user;

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
        ],
      ),
    );
  }
}
