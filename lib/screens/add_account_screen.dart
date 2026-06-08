import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:genauth/controllers/add_account_controller.dart';
import 'package:genauth/services/storage_service.dart';
import 'package:genauth/utils/l10n_extensions.dart';
import 'package:genauth/widgets/cam_scan_overlay.dart';
import 'package:genauth/widgets/snack_message.dart';

class AddAccountScreen extends StatefulWidget {
  const AddAccountScreen({super.key, this.importMode = false});

  final bool importMode;

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabs;
  late final AddAccountController _controller;

  void _onTabChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    if (!widget.importMode) {
      _tabs = TabController(length: 2, vsync: this);
      _tabs!.addListener(_onTabChanged);
    }
    _controller = AddAccountController(storage: StorageService.instance);
  }

  @override
  void dispose() {
    _tabs?.removeListener(_onTabChanged);
    _tabs?.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        centerTitle: false,
        title: Text(
          widget.importMode
              ? context.l10n.googleAuthImportAction
              : context.l10n.addAccount,
          style: const TextStyle(fontSize: 16),
        ),
        bottom: widget.importMode
            ? null
            : TabBar(
                controller: _tabs,
                tabs: [
                  Tab(text: context.l10n.scanQr),
                  Tab(text: context.l10n.manualEntry),
                ],
              ),
      ),
      body: widget.importMode
          ? _ScanQrTab(controller: _controller, isActive: true)
          : TabBarView(
              controller: _tabs,
              children: [
                _ScanQrTab(
                  controller: _controller,
                  isActive: _tabs?.index == 0,
                ),
                _ManualTab(controller: _controller),
              ],
            ),
    );
  }
}

class _ScanQrTab extends StatefulWidget {
  const _ScanQrTab({required this.controller, required this.isActive});

  final AddAccountController controller;
  final bool isActive;

  @override
  State<_ScanQrTab> createState() => _ScanQrTabState();
}

class _ScanQrTabState extends State<_ScanQrTab> with TickerProviderStateMixin {
  bool _done = false;
  bool _isStartingScanner = false;
  late final AnimationController _scanLineController;
  late final AnimationController _framePulseController;
  late MobileScannerController _scannerController;
  int _scannerSession = 0;

  @override
  void initState() {
    super.initState();
    _scannerController = _createScannerController();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _framePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
      lowerBound: 0.0,
      upperBound: 1.0,
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isActive) {
        unawaited(_startScanner());
      } else {
        _scanLineController.stop();
        _framePulseController.stop();
      }
    });
  }

  @override
  void didUpdateWidget(covariant _ScanQrTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive == widget.isActive) return;
    if (widget.isActive) {
      unawaited(_restartScanner(recreateController: true));
    } else {
      unawaited(_stopScanner());
      _scanLineController.stop();
      _framePulseController.stop();
    }
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    _framePulseController.dispose();
    unawaited(_scannerController.dispose());
    super.dispose();
  }

  MobileScannerController _createScannerController() {
    return MobileScannerController(
      autoStart: false,
      formats: const [BarcodeFormat.qrCode],
    );
  }

  Future<void> _startScanner() async {
    if (!mounted ||
        !widget.isActive ||
        _done ||
        _isStartingScanner ||
        _scannerController.value.isRunning) {
      return;
    }

    _isStartingScanner = true;
    try {
      await _scannerController.start();
    } catch (_) {
      // The scanner widget reflects startup errors through controller state.
    } finally {
      _isStartingScanner = false;
      if (mounted && _scannerController.value.error == null) {
        _scanLineController.repeat();
        _framePulseController.repeat(reverse: true);
      }
    }
  }

  Future<void> _stopScanner() async {
    try {
      await _scannerController.stop();
    } catch (_) {
      // Ignore native stop failures and let scanner recover on next start.
    }
  }

  Future<void> _restartScanner({bool recreateController = true}) async {
    if (!mounted || !widget.isActive) return;
    _done = false;
    await _stopScanner();
    if (recreateController) {
      final oldController = _scannerController;
      final newController = _createScannerController();
      setState(() {
        _scannerController = newController;
        _scannerSession++;
      });
      await oldController.dispose();
    }
    await _startScanner();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_done) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null) return;
    final isSupported =
        code.startsWith('otpauth://') ||
        code.startsWith('otpauth-migration://');
    if (!isSupported) return;

    _done = true;
    _scanLineController.stop();
    _framePulseController.stop();
    await _stopScanner();
    try {
      final importedCount = await widget.controller.saveFromQrCode(code);
      if (!mounted) return;

      final message = importedCount > 0
          ? context.l10n.accountsImported(importedCount)
          : context.l10n.accountsAlreadyImported;

      SnackMessage.show(
        context,
        message,
        icon: Icons.check_circle_outline,
        backgroundColor: Colors.green.shade600,
      );

      Navigator.pop(context, importedCount > 0);
    } catch (e) {
      _done = false;
      _scanLineController.repeat();
      _framePulseController.repeat(reverse: true);
      if (mounted) {
        SnackMessage.show(
          context,
          context.l10n.invalidQr('$e'),
          icon: Icons.error_outline,
          backgroundColor: Colors.red.shade600,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final scanBoxSize = math.min(
          math.min(size.width, size.height) * 0.72,
          320.0,
        );

        return ValueListenableBuilder<MobileScannerState>(
          valueListenable: _scannerController,
          builder: (context, scannerState, _) {
            return Stack(
              fit: StackFit.expand,
              children: [
                if (widget.isActive)
                  MobileScanner(
                    key: ValueKey(_scannerSession),
                    controller: _scannerController,
                    onDetect: _onDetect,
                    errorBuilder: (context, error) {
                      return _ScannerErrorView(
                        title: context.l10n.scannerUnavailableTitle,
                        message: error.errorDetails?.message?.isNotEmpty == true
                            ? error.errorDetails!.message!
                            : context.l10n.scannerUnavailableMessage,
                        actionLabel: context.l10n.scannerRetry,
                        onRetry: _restartScanner,
                      );
                    },
                  )
                else
                  const ColoredBox(color: Colors.black),
                if (scannerState.error == null)
                  CamScanOverlay(
                    scanAnimation: _scanLineController,
                    framePulseAnimation: _framePulseController,
                    scanBoxSize: scanBoxSize,
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ScannerErrorView extends StatelessWidget {
  const _ScannerErrorView({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onRetry,
  });

  final String title;
  final String message;
  final String actionLabel;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.qr_code_scanner_rounded,
                    size: 40,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      unawaited(onRetry());
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(actionLabel),
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

class _ManualTab extends StatefulWidget {
  const _ManualTab({required this.controller});

  final AddAccountController controller;

  @override
  State<_ManualTab> createState() => _ManualTabState();
}

class _ManualTabState extends State<_ManualTab> {
  final _formKey = GlobalKey<FormState>();
  final _labelCtrl = TextEditingController();
  final _issuerCtrl = TextEditingController();
  final _secretCtrl = TextEditingController();
  String _algorithm = 'SHA1';
  int _digits = 6;
  int _period = 30;
  bool _isHotp = false;

  @override
  void dispose() {
    _labelCtrl.dispose();
    _issuerCtrl.dispose();
    _secretCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await widget.controller.saveManualAccount(
      label: _labelCtrl.text,
      issuer: _issuerCtrl.text,
      secret: _secretCtrl.text,
      algorithm: _algorithm,
      digits: _digits,
      period: _period,
      isHotp: _isHotp,
    );
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _generateSecret() async {
    final s = await widget.controller.generateSecret();
    setState(() => _secretCtrl.text = s);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.edit_note, color: scheme.primary),
                    const SizedBox(width: 10),
                    Text(
                      l10n.manualEntry,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.addAccount,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: scheme.outline),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _labelCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.accountLabel,
                    labelStyle: TextStyle(fontSize: 12),
                    isDense: true,
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? l10n.requiredField : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _issuerCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.issuerLabel,
                    labelStyle: TextStyle(fontSize: 12),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _secretCtrl,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: l10n.secretKeyLabel,
                    labelStyle: TextStyle(fontSize: 12),
                    isDense: true,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.autorenew),
                      tooltip: l10n.generateNewSecret,
                      onPressed: _generateSecret,
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? l10n.requiredField : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _algorithm,
                        decoration: InputDecoration(
                          labelText: l10n.algorithm,
                          labelStyle: TextStyle(fontSize: 12),
                          isDense: true,
                        ),
                        items: ['SHA1', 'SHA256', 'SHA512']
                            .map(
                              (a) => DropdownMenuItem(value: a, child: Text(a)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _algorithm = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _digits,
                        decoration: InputDecoration(
                          labelText: l10n.digits,
                          labelStyle: TextStyle(fontSize: 12),
                          isDense: true,
                        ),
                        items: [6, 7, 8]
                            .map(
                              (d) =>
                                  DropdownMenuItem(value: d, child: Text('$d')),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _digits = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: Text(
                    l10n.hotpCounterBased,
                    style: TextStyle(fontSize: 12),
                  ),
                  subtitle: Text(
                    l10n.defaultTotpTimeBased,
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _isHotp,
                  onChanged: (v) => setState(() => _isHotp = v),
                  contentPadding: EdgeInsets.zero,
                ),
                if (!_isHotp) ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    initialValue: _period,
                    decoration: InputDecoration(
                      labelText: l10n.periodSeconds,
                      labelStyle: TextStyle(fontSize: 12),
                      isDense: true,
                    ),
                    items: [15, 30, 60, 90, 120]
                        .map(
                          (p) =>
                              DropdownMenuItem(value: p, child: Text('${p}s')),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _period = v!),
                  ),
                ],
                const SizedBox(height: 20),
                AnimatedBuilder(
                  animation: widget.controller,
                  builder: (context, child) {
                    return FilledButton.icon(
                      onPressed: widget.controller.saving ? null : _save,
                      icon: widget.controller.saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add_task),
                      label: Text(l10n.addAccount),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
