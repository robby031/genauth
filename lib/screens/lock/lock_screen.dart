import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genauth/providers/app_state_provider.dart';
import 'package:genauth/providers/lock_provider.dart';
import 'package:genauth/services/auth_service.dart';
import 'package:genauth/services/storage_service.dart';
import 'package:genauth/utils/app_assets.dart';
import 'package:genauth/utils/l10n_extensions.dart';
import 'package:genauth/screens/home/home_screen.dart';
import 'package:genauth/screens/pin/pin_screen.dart';
import 'package:genauth/widgets/snack_message.dart';

class LockScreen extends ConsumerStatefulWidget {
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
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final _storage = StorageService.instance;
  late final StateController<bool> _lockVisibility;
  bool _ready = false;
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
    _lockVisibility = ref.read(isLockScreenVisibleProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _lockVisibility.state = true;
      _bootstrap();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _lockVisibility.state = false;
    });
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final hasPin = await _storage.hasPin();
    if (!mounted) return;

    setState(() {
      _hasPin = hasPin;
      _ready = true;
    });
  }

  Future<void> _authenticateAndRoute({bool reportFailure = true}) async {
    final isAvailable = await AuthService.isAvailable();
    if (!mounted) return;
    if (!isAvailable) {
      SnackMessage.show(
        context,
        context.l10n.deviceAuthUnsupported,
        icon: Icons.warning_amber_outlined,
        backgroundColor: Colors.orange.shade600,
      );
      return;
    }

    final ok = await ref
        .read(lockProvider.notifier)
        .authenticate(reportFailure: reportFailure);
    if (!mounted) return;

    if (!ok && reportFailure) {
      SnackMessage.show(
        context,
        context.l10n.authFailed,
        icon: Icons.error_outline,
        backgroundColor: Colors.red.shade600,
      );
    }

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

    ref.read(lockProvider.notifier).clearError();
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
    final lockState = ref.watch(lockProvider);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 240),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset(
                    AppAssets.logoNoBackground,
                    width: 84,
                    height: 84,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.appTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.authenticator,
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(color: scheme.outline),
                  ),
                  const SizedBox(height: 8),
                  if (!_ready || lockState.authenticating)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _openPin,
                            icon: const Icon(Icons.pin_outlined),
                            label: Text(context.l10n.usePin),
                            style: FilledButton.styleFrom(
                              backgroundColor: scheme.secondary,
                              foregroundColor: scheme.onSecondary,
                              visualDensity: VisualDensity.compact,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: _authenticateAndRoute,
                          style: FilledButton.styleFrom(
                            backgroundColor: scheme.primary,
                            foregroundColor: scheme.onPrimary,
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            minimumSize: const Size(44, 40),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          child: const Icon(Icons.fingerprint),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
