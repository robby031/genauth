import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genauth/providers/app_state_provider.dart';
import 'package:genauth/services/android_autofill_settings_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:genauth/screens/audit/audit_log_screen.dart';
import 'package:genauth/screens/backup/backup_screen.dart';
import 'package:genauth/screens/pin/pin_screen.dart';
import 'package:genauth/services/app_info_service.dart';
import 'package:genauth/services/storage_service.dart';
import 'package:genauth/utils/app_links.dart';
import 'package:genauth/utils/l10n_extensions.dart';
import 'package:genauth/widgets/snack_message.dart';
import 'widgets/drawer_header.dart';
import 'widgets/drawer_footer.dart';
import 'widgets/section_group.dart';
import 'widgets/menu_tile.dart';

class DrawerScreen extends ConsumerStatefulWidget {
  const DrawerScreen({
    super.key,
    required this.onLock,
    required this.onAbout,
    required this.onOpenOnboarding,
  });

  final VoidCallback onLock;
  final VoidCallback onAbout;
  final VoidCallback onOpenOnboarding;

  @override
  ConsumerState<DrawerScreen> createState() => _DrawerScreenState();
}

class _DrawerScreenState extends ConsumerState<DrawerScreen> {
  final StorageService _storage = StorageService.instance;

  bool _hasPin = false;
  bool _hasPanicPin = false;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadDrawerState();
  }

  Future<void> _loadDrawerState() async {
    final results = await Future.wait<Object>([
      _storage.hasPin(),
      _storage.hasPanicPin(),
      AppInfoService.versionLabel(),
    ]);
    if (!mounted) return;

    setState(() {
      _hasPin = results[0] as bool;
      _hasPanicPin = results[1] as bool;
      _appVersion = results[2] as String;
    });
  }

  Future<void> _openPinSetup() async {
    Navigator.pop(context);
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const PinScreen(mode: PinMode.setup)),
    );
    if (ok == true) {
      await _loadDrawerState();
    }
  }

  Future<void> _removePin() async {
    Navigator.pop(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.removePinOption),
        content: Text(context.l10n.removeAccount(context.l10n.usePin)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _storage.clearPin();
    await _loadDrawerState();
    if (!mounted) return;
    SnackMessage.show(
      context,
      context.l10n.pinRemoved,
      icon: Icons.check_circle_outline,
      backgroundColor: Colors.green.shade600,
    );
  }

  Future<void> _openPanicPinSetup() async {
    Navigator.pop(context);
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const PinScreen(mode: PinMode.panicSetup),
      ),
    );
    if (ok == true) {
      await _loadDrawerState();
    }
  }

  Future<void> _removePanicPin() async {
    Navigator.pop(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.removePanicPinOption),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _storage.clearPanicPin();
    await _loadDrawerState();
    if (!mounted) return;
    SnackMessage.show(
      context,
      context.l10n.panicPinRemoved,
      icon: Icons.check_circle_outline,
      backgroundColor: Colors.green.shade600,
    );
  }

  Future<void> _openGithubRepo(BuildContext context) async {
    final ok = await launchUrl(
      Uri.parse(AppLinks.repoUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      SnackMessage.show(
        context,
        context.l10n.githubLinkOpenFailed,
        icon: Icons.error_outline,
        backgroundColor: Colors.red.shade600,
      );
    }
  }

  Future<void> _openPrivacyPolicyDirect() async {
    Navigator.pop(context);

    final raw = AppLinks.privacyPolicyUrl.trim();
    if (raw.isEmpty) {
      if (!mounted) return;
      SnackMessage.show(
        context,
        context.l10n.privacyPolicyNotConfigured,
        icon: Icons.error_outline,
        backgroundColor: Colors.red.shade600,
      );
      return;
    }

    final uri = Uri.tryParse(raw);
    if (uri == null ||
        !(uri.hasScheme && (uri.scheme == 'https' || uri.scheme == 'http'))) {
      if (!mounted) return;
      SnackMessage.show(
        context,
        context.l10n.privacyPolicyInvalidUrl,
        icon: Icons.error_outline,
        backgroundColor: Colors.red.shade600,
      );
      return;
    }

    final ok = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    if (!ok && mounted) {
      SnackMessage.show(
        context,
        context.l10n.privacyPolicyLoadFailed,
        icon: Icons.error_outline,
        backgroundColor: Colors.red.shade600,
      );
    }
  }

  Future<void> _openTermsConditionsDirect() async {
    Navigator.pop(context);

    final raw = AppLinks.termsConditionsUrl.trim();
    if (raw.isEmpty) {
      if (!mounted) return;
      SnackMessage.show(
        context,
        context.l10n.termsConditionsNotConfigured,
        icon: Icons.error_outline,
        backgroundColor: Colors.red.shade600,
      );
      return;
    }

    final uri = Uri.tryParse(raw);
    if (uri == null ||
        !(uri.hasScheme && (uri.scheme == 'https' || uri.scheme == 'http'))) {
      if (!mounted) return;
      SnackMessage.show(
        context,
        context.l10n.termsConditionsInvalidUrl,
        icon: Icons.error_outline,
        backgroundColor: Colors.red.shade600,
      );
      return;
    }

    final ok = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    if (!ok && mounted) {
      SnackMessage.show(
        context,
        context.l10n.termsConditionsLoadFailed,
        icon: Icons.error_outline,
        backgroundColor: Colors.red.shade600,
      );
    }
  }

  Future<void> _openAutofillServiceSettings() async {
    Navigator.pop(context);

    final ok = await AndroidAutofillSettingsService.openAutofillSettings();
    if (!ok && mounted) {
      SnackMessage.show(
        context,
        context.l10n.autofillServiceOpenFailed,
        icon: Icons.error_outline,
        backgroundColor: Colors.red.shade600,
      );
    }
  }

  void _showLanguageBottomSheet(BuildContext context, Locale currentLocale) {
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MenuTile(
                icon: Icons.language,
                title: context.l10n.english,
                trailing: currentLocale.languageCode == 'en'
                    ? Icon(Icons.check_circle, color: scheme.primary)
                    : null,
                onTap: () {
                  ref
                      .read(localeProvider.notifier)
                      .setLocale(const Locale('en'));
                  Navigator.pop(context);
                },
              ),
              MenuTile(
                icon: Icons.translate,
                title: context.l10n.indonesian,
                trailing: currentLocale.languageCode == 'id'
                    ? Icon(Icons.check_circle, color: scheme.primary)
                    : null,
                onTap: () {
                  ref
                      .read(localeProvider.notifier)
                      .setLocale(const Locale('id'));
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final currentLocale = ref.watch(localeProvider);

    final securityItems = <Widget>[
      MenuTile(
        icon: Icons.lock_outline,
        title: l10n.lockapp,
        onTap: widget.onLock,
      ),
      MenuTile(
        icon: Icons.pin_outlined,
        title: _hasPin ? l10n.removePinOption : l10n.setPinOption,
        onTap: _hasPin ? _removePin : _openPinSetup,
      ),
      MenuTile(
        icon: Icons.warning_amber_outlined,
        title: _hasPanicPin
            ? l10n.removePanicPinOption
            : l10n.setPanicPinOption,
        subtitle: l10n.panicPinOptionSubtitle,
        onTap: _hasPanicPin ? _removePanicPin : _openPanicPinSetup,
      ),
    ];

    final dataItems = <Widget>[
      if (Platform.isAndroid)
        MenuTile(
          icon: Icons.sms_outlined,
          title: l10n.autofillServiceMenu,
          subtitle: l10n.autofillServiceSubtitle,
          onTap: _openAutofillServiceSettings,
        ),
      MenuTile(
        icon: Icons.backup_outlined,
        title: l10n.backupAndRestore,
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BackupScreen()),
          );
        },
      ),
      MenuTile(
        icon: Icons.history_edu_outlined,
        title: l10n.auditLogMenu,
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AuditLogScreen()),
          );
        },
      ),
      MenuTile(
        icon: Icons.privacy_tip_outlined,
        title: l10n.privacyPolicyMenu,
        onTap: _openPrivacyPolicyDirect,
      ),
      MenuTile(
        icon: Icons.gavel_outlined,
        title: l10n.termsConditionsMenu,
        onTap: _openTermsConditionsDirect,
      ),
    ];

    final appItems = <Widget>[
      MenuTile(
        icon: Icons.info_outline,
        title: l10n.about,
        onTap: widget.onAbout,
      ),
      MenuTile(
        icon: Icons.rocket_launch_outlined,
        title: l10n.getStarted,
        onTap: widget.onOpenOnboarding,
      ),
      MenuTile(
        icon: Icons.language,
        title: l10n.language,
        subtitle: currentLocale.languageCode == 'id'
            ? l10n.indonesian
            : l10n.english,
        trailing: Icon(
          Icons.keyboard_arrow_down_rounded,
          color: Theme.of(context).colorScheme.primary,
        ),
        onTap: () => _showLanguageBottomSheet(context, currentLocale),
      ),
    ];

    return Drawer(
      width: 292,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          children: [
            AppDrawerHeader(),
            const SizedBox(height: 10),
            SectionGroup(
              title: l10n.drawerSectionSecurity,
              children: securityItems,
            ),
            SectionGroup(title: l10n.drawerSectionData, children: dataItems),
            SectionGroup(title: l10n.drawerSectionApp, children: appItems),
            const SizedBox(height: 12),
            DrawerFooter(
              appVersion: _appVersion,
              onOpenGithub: () => _openGithubRepo(context),
            ),
          ],
        ),
      ),
    );
  }
}
