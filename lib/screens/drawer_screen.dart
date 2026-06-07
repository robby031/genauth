import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/locale_service.dart';
import '../utils/app_assets.dart';
import '../utils/l10n_extensions.dart';
import 'backup_screen.dart';

class DrawerScreen extends StatelessWidget {
  static final Uri _repoUrl = Uri.parse(
    'https://github.com/robby031/genotp-go',
  );

  final VoidCallback onLock;
  final VoidCallback onAbout;
  const DrawerScreen({super.key, required this.onLock, required this.onAbout});

  Future<void> _openGithubRepo(BuildContext context) async {
    final ok = await launchUrl(_repoUrl, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open GitHub link.')),
      );
    }
  }

  Widget _menuTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(14),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        minLeadingWidth: 20,
        visualDensity: const VisualDensity(horizontal: 0, vertical: -1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Icon(icon, color: scheme.primary, size: 20),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle,
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
              ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
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
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _menuTile(
                context: context,
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
              const SizedBox(height: 8),
              _menuTile(
                context: context,
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
    final scheme = Theme.of(context).colorScheme;
    return Drawer(
      width: 292,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scheme.primaryContainer,
                      scheme.surfaceContainerHigh,
                    ],
                  ),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: Image.asset(AppAssets.logoNoBackground),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GenAuth',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: scheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            context.l10n.authenticator,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontSize: 11,
                                  color: scheme.onPrimaryContainer.withValues(
                                    alpha: 0.78,
                                  ),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _menuTile(
                context: context,
                icon: Icons.lock_outline,
                title: context.l10n.lockapp,
                onTap: onLock,
              ),
              const SizedBox(height: 8),
              _menuTile(
                context: context,
                icon: Icons.backup_outlined,
                title: context.l10n.backupAndRestore,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BackupScreen()),
                  );
                },
              ),
              const SizedBox(height: 8),
              _menuTile(
                context: context,
                icon: Icons.info_outline,
                title: context.l10n.about,
                onTap: onAbout,
              ),
              const SizedBox(height: 8),
              ValueListenableBuilder<Locale>(
                valueListenable: LocaleService.localeNotifier,
                builder: (context, currentLocale, child) {
                  final currentLangName = currentLocale.languageCode == 'id'
                      ? context.l10n.indonesian
                      : context.l10n.english;

                  return _menuTile(
                    context: context,
                    icon: Icons.language,
                    title: context.l10n.language,
                    subtitle: currentLangName,
                    trailing: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: scheme.primary,
                    ),
                    onTap: () =>
                        _showLanguageBottomSheet(context, currentLocale),
                  );
                },
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    tooltip: 'Open GitHub repository',
                    onPressed: () => _openGithubRepo(context),
                    icon: SvgPicture.asset(
                      AppAssets.githubSvg,
                      width: 18,
                      height: 18,
                      colorFilter: ColorFilter.mode(
                        scheme.primary,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'GenAuth',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontSize: 11,
                  color: scheme.outline,
                  letterSpacing: 0.4,
                ),
              ),
              Text(
                '© 2026 GenAuth. All rights reserved.',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontSize: 10,
                  color: scheme.outlineVariant,
                ),
              ),
              Text(
                'Version 1.0.0',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontSize: 10,
                  color: scheme.outlineVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
