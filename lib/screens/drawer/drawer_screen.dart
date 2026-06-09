import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:genauth/screens/audit/audit_log_screen.dart';
import 'package:genauth/screens/backup/backup_screen.dart';
import 'package:genauth/screens/pin_screen.dart';
import 'package:genauth/services/app_info_service.dart';
import 'package:genauth/services/locale_service.dart';
import 'package:genauth/services/storage_service.dart';
import 'package:genauth/utils/app_links.dart';
import 'package:genauth/utils/l10n_extensions.dart';
import 'package:genauth/widgets/snack_message.dart';
import 'widgets/drawer_header.dart';
import 'widgets/drawer_footer.dart';

class DrawerScreen extends StatefulWidget {
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
  State<DrawerScreen> createState() => _DrawerScreenState();
}

class _DrawerScreenState extends State<DrawerScreen> {
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
              _MenuTile(
                icon: Icons.language,
                title: context.l10n.english,
                trailing: currentLocale.languageCode == 'en'
                    ? Icon(Icons.check_circle, color: scheme.primary)
                    : null,
                onTap: () {
                  LocaleService.changeLocale('en');
                  Navigator.pop(context);
                },
              ),
              _MenuTile(
                icon: Icons.translate,
                title: context.l10n.indonesian,
                trailing: currentLocale.languageCode == 'id'
                    ? Icon(Icons.check_circle, color: scheme.primary)
                    : null,
                onTap: () {
                  LocaleService.changeLocale('id');
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

    final securityItems = <Widget>[
      _MenuTile(
        icon: Icons.lock_outline,
        title: l10n.lockapp,
        onTap: widget.onLock,
      ),
      _MenuTile(
        icon: Icons.pin_outlined,
        title: _hasPin ? l10n.removePinOption : l10n.setPinOption,
        onTap: _hasPin ? _removePin : _openPinSetup,
      ),
      _MenuTile(
        icon: Icons.warning_amber_outlined,
        title: _hasPanicPin
            ? l10n.removePanicPinOption
            : l10n.setPanicPinOption,
        subtitle: l10n.panicPinOptionSubtitle,
        onTap: _hasPanicPin ? _removePanicPin : _openPanicPinSetup,
      ),
    ];

    final dataItems = <Widget>[
      _MenuTile(
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
      _MenuTile(
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
      _MenuTile(
        icon: Icons.privacy_tip_outlined,
        title: l10n.privacyPolicyMenu,
        onTap: _openPrivacyPolicyDirect,
      ),
      _MenuTile(
        icon: Icons.gavel_outlined,
        title: l10n.termsConditionsMenu,
        onTap: _openTermsConditionsDirect,
      ),
    ];

    final appItems = <Widget>[
      _MenuTile(
        icon: Icons.info_outline,
        title: l10n.about,
        onTap: widget.onAbout,
      ),
      _MenuTile(
        icon: Icons.rocket_launch_outlined,
        title: l10n.getStarted,
        onTap: widget.onOpenOnboarding,
      ),
      ValueListenableBuilder<Locale>(
        valueListenable: LocaleService.localeNotifier,
        builder: (context, currentLocale, child) {
          final currentLangName = currentLocale.languageCode == 'id'
              ? l10n.indonesian
              : l10n.english;

          return _MenuTile(
            icon: Icons.language,
            title: l10n.language,
            subtitle: currentLangName,
            trailing: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            onTap: () => _showLanguageBottomSheet(context, currentLocale),
          );
        },
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
            _SectionGroup(
              title: l10n.drawerSectionSecurity,
              children: securityItems,
            ),
            _SectionGroup(title: l10n.drawerSectionData, children: dataItems),
            _SectionGroup(title: l10n.drawerSectionApp, children: appItems),
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

class _SectionGroup extends StatelessWidget {
  const _SectionGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
            child: Text(
              title,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: scheme.surfaceContainerLow.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 2,
          ),
          minLeadingWidth: 20,
          visualDensity: const VisualDensity(horizontal: 0, vertical: -1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          leading: Icon(icon, color: scheme.primary, size: 20),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: subtitle == null
              ? null
              : Text(
                  subtitle!,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
          trailing: trailing,
          onTap: onTap,
        ),
      ),
    );
  }
}
