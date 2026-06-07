import 'package:flutter/material.dart';
import '../controllers/lock_controller.dart';
import '../utils/app_assets.dart';
import '../utils/l10n_extensions.dart';
import 'home_screen.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _controller = LockController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _authenticateAndRoute(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _authenticateAndRoute() async {
    final ok = await _controller.authenticate();
    if (!mounted) return;

    if (ok) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      AppAssets.logoNoBackground,
                      width: 84,
                      height: 84,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'GenAuth',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.l10n.authenticator,
                      style: Theme.of(
                        context,
                      ).textTheme.titleSmall?.copyWith(color: scheme.outline),
                    ),
                    const SizedBox(height: 40),
                    if (_controller.authenticating)
                      const CircularProgressIndicator()
                    else ...[
                      if (_controller.hasError) ...[
                        Text(
                          context.l10n.authFailed,
                          style: TextStyle(color: scheme.error),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                      ],
                      FilledButton.icon(
                        onPressed: _authenticateAndRoute,
                        icon: const Icon(Icons.fingerprint),
                        label: Text(context.l10n.unlock),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
