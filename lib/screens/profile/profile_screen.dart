import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genauth/providers/google_account_provider.dart';
import 'package:genauth/providers/google_profile_provider.dart';
import 'package:genauth/services/audit_log_service.dart';
import 'package:genauth/utils/l10n_extensions.dart';
import 'package:genauth/widgets/snack_message.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _busy = false;

  Future<void> _refreshProfile() async {
    if (_busy) return;

    setState(() => _busy = true);
    try {
      await ref.read(googleAccountProvider).refreshCurrentProfile();
      await ref.read(googleProfileProvider.notifier).reload();

      if (!mounted) return;
      SnackMessage.show(
        context,
        context.l10n.profileUpdated,
        icon: Icons.check_circle_outline,
        backgroundColor: Colors.green.shade600,
      );
    } catch (e) {
      if (!mounted) return;
      SnackMessage.show(
        context,
        e.toString(),
        icon: Icons.error_outline,
        backgroundColor: Colors.red.shade600,
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _signOut() async {
    if (_busy) return;

    final service = ref.read(googleAccountProvider);
    final profile = ref.read(googleProfileProvider).valueOrNull;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.driveBackupSignOut),
        content: Text(
          context.l10n.driveBackupSignedInAs(
            profile?.email ?? service.currentUser?.email ?? '',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.driveBackupSignOut),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      await service.signOut();
      await AuditLogService.instance.log('google_logout');

      if (!mounted) return;
      SnackMessage.show(
        context,
        context.l10n.driveBackupSignOut,
        icon: Icons.cloud_off_rounded,
        backgroundColor: Colors.blueGrey.shade600,
      );
      Navigator.pop(context);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Widget _profileRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: scheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final profileAsync = ref.watch(googleProfileProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        centerTitle: false,
        title: Text(
          context.l10n.profileTitle,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          IconButton(
            onPressed: _busy ? null : _refreshProfile,
            tooltip: context.l10n.profileRefresh,
            icon: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
        data: (profile) {
          if (profile == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.account_circle_outlined,
                      size: 56,
                      color: scheme.outline,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.l10n.profileSignInPrompt,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final fullName = [
            profile.givenName,
            profile.familyName,
          ].whereType<String>().where((v) => v.trim().isNotEmpty).join(' ');

          final displayName = profile.displayName;
          final headerName =
              (displayName != null && displayName.trim().isNotEmpty)
              ? displayName
              : (fullName.isNotEmpty ? fullName : profile.email);

          final avatarUrl = profile.photoUrl;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 34,
                          backgroundImage: avatarUrl != null
                              ? NetworkImage(avatarUrl)
                              : null,
                          child: avatarUrl == null
                              ? const Icon(Icons.person_outline, size: 30)
                              : null,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          headerName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profile.email,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.outline),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          context.l10n.profileSectionGoogleAccount,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        _profileRow(
                          context: context,
                          icon: Icons.badge_outlined,
                          label: context.l10n.profileDisplayName,
                          value:
                              displayName ?? context.l10n.profileNotAvailable,
                        ),
                        _profileRow(
                          context: context,
                          icon: Icons.person_outline,
                          label: context.l10n.profileGivenName,
                          value:
                              profile.givenName ??
                              context.l10n.profileNotAvailable,
                        ),
                        _profileRow(
                          context: context,
                          icon: Icons.person_2_outlined,
                          label: context.l10n.profileFamilyName,
                          value:
                              profile.familyName ??
                              context.l10n.profileNotAvailable,
                        ),
                        _profileRow(
                          context: context,
                          icon: Icons.alternate_email,
                          label: context.l10n.profileEmail,
                          value: profile.email,
                        ),
                        _profileRow(
                          context: context,
                          icon: Icons.language,
                          label: context.l10n.profileLocale,
                          value:
                              profile.localeCode ??
                              context.l10n.profileNotAvailable,
                        ),
                        _profileRow(
                          context: context,
                          icon: Icons.fingerprint,
                          label: context.l10n.profileGoogleId,
                          value:
                              profile.googleId ??
                              context.l10n.profileNotAvailable,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _busy ? null : _signOut,
                  icon: const Icon(Icons.logout),
                  label: Text(context.l10n.driveBackupSignOut),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
