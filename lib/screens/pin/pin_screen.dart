import 'package:flutter/material.dart';
import 'package:genauth/services/audit_log_service.dart';
import 'package:genauth/services/storage_service.dart';
import 'package:genauth/utils/app_assets.dart';
import 'package:genauth/utils/l10n_extensions.dart';
import 'package:genauth/widgets/snack_message.dart';

enum PinMode { setup, verify, panicSetup }

class PinScreen extends StatefulWidget {
  final PinMode mode;

  const PinScreen({super.key, required this.mode});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  static const _pinLength = 6;

  String _pin = '';
  String? _setupFirst;
  bool _isConfirming = false;
  String? _errorMessage;
  bool _loading = false;

  String get _title {
    if (widget.mode == PinMode.verify) return context.l10n.pinEnterTitle;
    if (widget.mode == PinMode.panicSetup) {
      return _isConfirming
          ? context.l10n.panicPinConfirmTitle
          : context.l10n.panicPinSetupTitle;
    }
    return _isConfirming
        ? context.l10n.pinConfirmTitle
        : context.l10n.pinSetupTitle;
  }

  String get _subtitle {
    if (widget.mode == PinMode.verify) return '';
    if (widget.mode == PinMode.panicSetup) {
      return _isConfirming
          ? context.l10n.panicPinConfirmDesc
          : context.l10n.panicPinSetupDesc;
    }
    return _isConfirming
        ? context.l10n.pinConfirmDesc
        : context.l10n.pinSetupDesc;
  }

  void _append(String digit) {
    if (_pin.length >= _pinLength || _loading) return;
    setState(() {
      _pin += digit;
      _errorMessage = null;
    });
    if (_pin.length == _pinLength) _onComplete();
  }

  void _backspace() {
    if (_pin.isEmpty || _loading) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _onComplete() async {
    if (widget.mode == PinMode.verify) {
      await _verify();
    } else {
      await _setupStep();
    }
  }

  Future<void> _verify() async {
    setState(() => _loading = true);
    final storage = StorageService();
    await AuditLogService.instance.log('auth_pin_attempt');
    final isPanic = await storage.verifyPanicPin(_pin);
    if (isPanic) {
      await AuditLogService.instance.log(
        'auth_pin_panic_trigger',
        status: 'critical',
      );
      await storage.activateDecoyVaultForDuress();
      if (!mounted) return;
      Navigator.pop(context, true);
      return;
    }

    final ok = await storage.verifyPin(_pin);
    await AuditLogService.instance.log(
      'auth_pin_result',
      status: ok ? 'success' : 'failed',
    );
    if (!mounted) return;
    if (ok) {
      await storage.activateRealVault();
      Navigator.pop(context, true);
    } else {
      setState(() {
        _loading = false;
        _pin = '';
        _errorMessage = context.l10n.pinWrong;
      });
    }
  }

  Future<void> _setupStep() async {
    if (!_isConfirming) {
      setState(() {
        _setupFirst = _pin;
        _pin = '';
        _isConfirming = true;
      });
      return;
    }
    // Confirmation step.
    if (_pin != _setupFirst) {
      setState(() {
        _pin = '';
        _setupFirst = null;
        _isConfirming = false;
        _errorMessage = context.l10n.pinMismatch;
      });
      return;
    }
    setState(() => _loading = true);
    if (widget.mode == PinMode.panicSetup) {
      await StorageService().savePanicPin(_pin);
    } else {
      await StorageService().savePin(_pin);
    }
    if (!mounted) return;
    SnackMessage.show(
      context,
      widget.mode == PinMode.panicSetup
          ? context.l10n.panicPinSaved
          : context.l10n.pinSaved,
      icon: Icons.check_circle_outline,
      backgroundColor: Colors.green,
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: widget.mode == PinMode.verify
          ? null
          : AppBar(
              titleSpacing: 0,
              centerTitle: false,
              title: Text(_title, style: const TextStyle(fontSize: 16)),
            ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.mode == PinMode.verify) ...[
                  Image.asset(
                    AppAssets.logoNoBackground,
                    width: 72,
                    height: 72,
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  _title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (_subtitle.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    _subtitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: scheme.outline),
                  ),
                ],
                const SizedBox(height: 32),
                // PIN dots
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(_pinLength, (i) {
                    final filled = i < _pin.length;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: filled
                              ? scheme.primary
                              : scheme.outlineVariant,
                        ),
                      ),
                    );
                  }),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: scheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                // Numpad
                _Numpad(
                  onDigit: _append,
                  onBackspace: _backspace,
                  loading: _loading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Numpad extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onBackspace;
  final bool loading;

  const _Numpad({
    required this.onDigit,
    required this.onBackspace,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '<'],
    ];
    return Column(
      children: keys.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: row.map((key) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _NumKey(
                  label: key,
                  onDigit: key.isEmpty ? null : onDigit,
                  onBackspace: key == '<' ? onBackspace : null,
                  enabled: !loading,
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

class _NumKey extends StatelessWidget {
  final String label;
  final void Function(String)? onDigit;
  final VoidCallback? onBackspace;
  final bool enabled;

  const _NumKey({
    required this.label,
    this.onDigit,
    this.onBackspace,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (label.isEmpty) return const SizedBox(width: 72, height: 72);

    final isBackspace = label == '<';
    return SizedBox(
      width: 72,
      height: 72,
      child: Material(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(36),
        child: InkWell(
          borderRadius: BorderRadius.circular(36),
          onTap: enabled
              ? (isBackspace ? onBackspace : () => onDigit!(label))
              : null,
          child: Center(
            child: isBackspace
                ? Icon(
                    Icons.backspace_outlined,
                    color: scheme.onSurface,
                    size: 22,
                  )
                : Text(
                    label,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
