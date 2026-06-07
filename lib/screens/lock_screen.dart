import 'package:flutter/material.dart';
import '../controllers/lock_controller.dart';
import 'package:genauth/services/app_lock_state.dart';
import 'package:genauth/services/auth_service.dart';
import 'package:genauth/services/storage_service.dart';
import 'package:genauth/utils/app_assets.dart';
import 'package:genauth/utils/l10n_extensions.dart';
import 'package:genauth/screens/home_screen.dart';
import 'package:genauth/screens/pin_screen.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({
    super.key,
    this.onAuthenticated,
    this.replaceWithHomeOnSuccess = true,
    this.navigatorState,
  });

  final VoidCallback? onAuthenticated;
  final bool replaceWithHomeOnSuccess;
  final NavigatorState? navigatorState;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _controller = LockController();
  final _storage = StorageService.instance;
  bool _ready = false;
  bool _supportsBiometric = false;
  bool _hasPin = false;

  NavigatorState? get _navigator {
    final injectedNavigator = widget.navigatorState;
    if (injectedNavigator != null) {
      return injectedNavigator;
    }
    return Navigator.maybeOf(context);
  }

  @override
  void initState() {
    super.initState();
    AppLockState.isLockScreenVisible.value = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    AppLockState.isLockScreenVisible.value = false;
    _controller.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final supportsBiometric = await AuthService.hasEnrolledBiometrics();
    final hasPin = await _storage.hasPin();
    if (!mounted) return;

    setState(() {
      _supportsBiometric = supportsBiometric;
      _hasPin = hasPin;
      _ready = true;
    });

    if (supportsBiometric) {
      await _authenticateAndRoute(reportFailure: false);
    }
  }

  Future<void> _authenticateAndRoute({bool reportFailure = true}) async {
    final ok = await _controller.authenticate(reportFailure: reportFailure);
    if (!mounted) return;

    if (ok) {
      widget.onAuthenticated?.call();
      if (!widget.replaceWithHomeOnSuccess) {
        return;
      }
      final navigator = _navigator;
      if (navigator == null) return;
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  Future<void> _openPin() async {
    if (!mounted) return;

    _controller.clearError();
    final mode = _hasPin ? PinMode.verify : PinMode.setup;
    final navigator = _navigator;
    if (navigator == null) return;
    final ok = await navigator.push<bool>(
      MaterialPageRoute(builder: (_) => PinScreen(mode: mode)),
    );
    if (!mounted || ok != true) return;
    widget.onAuthenticated?.call();
    if (!widget.replaceWithHomeOnSuccess) {
      return;
    }
    navigator.pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final showUnlock = _supportsBiometric;
        final showPin = true;

        return Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
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
                        'GenAuth',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.authenticator,
                        textAlign: TextAlign.center,
                        style: Theme.of(
                          context,
                        ).textTheme.titleSmall?.copyWith(color: scheme.outline),
                      ),
                      const SizedBox(height: 40),
                      if (!_ready || _controller.authenticating)
                        const Center(child: CircularProgressIndicator())
                      else ...[
                        if (_controller.hasError) ...[
                          Text(
                            context.l10n.authFailed,
                            style: TextStyle(color: scheme.error),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                        ],
                        if (showUnlock)
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _authenticateAndRoute,
                              child: Text(context.l10n.unlock),
                            ),
                          ),
                        if (showUnlock && showPin) ...[
                          const SizedBox(height: 12),
                        ],
                        if (showPin)
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: _openPin,
                              child: Text(context.l10n.usePin),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
