import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:genauth/screens/lock/lock_screen.dart';
import 'package:genauth/services/audit_log_service.dart';
import 'package:genauth/services/google_account_service.dart';
import 'package:genauth/utils/app_assets.dart';
import 'package:genauth/utils/l10n_extensions.dart';

class GoogleSignInScreen extends StatefulWidget {
  const GoogleSignInScreen({super.key});

  @override
  State<GoogleSignInScreen> createState() => _GoogleSignInScreenState();
}

class _GoogleSignInScreenState extends State<GoogleSignInScreen> {
  bool _busy = false;
  String? _error;

  void _continueWithoutGoogle() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LockScreen()),
    );
  }

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    await AuditLogService.instance.log('google_login_attempt');

    try {
      await GoogleAccountService.instance.signIn();
      await AuditLogService.instance.log('google_login_success');
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LockScreen()),
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        await AuditLogService.instance.log(
          'google_login_canceled',
          status: 'failed',
        );
        if (mounted) setState(() => _busy = false);
        return;
      }
      await AuditLogService.instance.log(
        'google_login_failed',
        status: 'failed',
        detail: e.code.name,
      );
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.description ?? e.code.name;
        });
      }
    } catch (e) {
      await AuditLogService.instance.log(
        'google_login_failed',
        status: 'failed',
        detail: e.toString(),
      );
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset(
                    AppAssets.logoNoBackground,
                    width: 84,
                    height: 84,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.googleLoginTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.googleLoginSubtitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _BulletItem(
                    icon: Icons.verified_user_outlined,
                    text: l10n.googleLoginBenefit1,
                  ),
                  const SizedBox(height: 8),
                  _BulletItem(
                    icon: Icons.cloud_outlined,
                    text: l10n.googleLoginBenefit2,
                  ),
                  const SizedBox(height: 8),
                  _BulletItem(
                    icon: Icons.lock_outline,
                    text: l10n.googleLoginBenefit3,
                  ),
                  const SizedBox(height: 32),
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: scheme.errorContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: scheme.onErrorContainer,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: TextStyle(color: scheme.onErrorContainer),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  FilledButton.icon(
                    onPressed: _busy ? null : _signIn,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.login),
                    label: Text(
                      _busy ? l10n.googleLoginInProgress : l10n.googleLoginCta,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _busy ? null : _continueWithoutGoogle,
                    child: Text(l10n.skip),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.googleLoginDisclaimer,
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: scheme.outline),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BulletItem extends StatelessWidget {
  const _BulletItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: scheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
