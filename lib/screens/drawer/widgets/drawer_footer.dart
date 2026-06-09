import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:genauth/utils/app_assets.dart';
import 'package:genauth/utils/l10n_extensions.dart';

class DrawerFooter extends StatelessWidget {
  const DrawerFooter({
    super.key,
    required this.appVersion,
    required this.onOpenGithub,
  });

  final String appVersion;
  final VoidCallback onOpenGithub;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.filledTonal(
              tooltip: context.l10n.openGithubRepository,
              onPressed: onOpenGithub,
              icon: SvgPicture.asset(
                AppAssets.githubSvg,
                width: 18,
                height: 18,
                colorFilter: ColorFilter.mode(scheme.primary, BlendMode.srcIn),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          context.l10n.appTitle,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontSize: 11,
            color: scheme.outline,
            letterSpacing: 0.4,
          ),
        ),
        Text(
          '© 2026 ${context.l10n.appTitle}. ${context.l10n.allRightsReserved}',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontSize: 10,
            color: scheme.outlineVariant,
          ),
        ),
        Text(
          context.l10n.versionLabel(appVersion.isEmpty ? '...' : appVersion),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontSize: 10,
            color: scheme.outlineVariant,
          ),
        ),
      ],
    );
  }
}
