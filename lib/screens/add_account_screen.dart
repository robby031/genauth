import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:genauth/controllers/add_account_controller.dart';
import 'package:genauth/services/storage_service.dart';
import 'package:genauth/utils/l10n_extensions.dart';
import 'package:genauth/widgets/cam_scan_overlay.dart';

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

  @override
  void initState() {
    super.initState();
    if (!widget.importMode) {
      _tabs = TabController(length: 2, vsync: this);
    }
    _controller = AddAccountController(storage: StorageService.instance);
  }

  @override
  void dispose() {
    _tabs?.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.importMode
              ? context.l10n.googleAuthImportAction
              : context.l10n.addAccount,
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
          ? _ScanQrTab(controller: _controller)
          : TabBarView(
              controller: _tabs,
              children: [
                _ScanQrTab(controller: _controller),
                _ManualTab(controller: _controller),
              ],
            ),
    );
  }
}

class _ScanQrTab extends StatefulWidget {
  const _ScanQrTab({required this.controller});

  final AddAccountController controller;

  @override
  State<_ScanQrTab> createState() => _ScanQrTabState();
}

class _ScanQrTabState extends State<_ScanQrTab> with TickerProviderStateMixin {
  bool _done = false;
  late final AnimationController _scanLineController;
  late final AnimationController _framePulseController;

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    _framePulseController.dispose();
    super.dispose();
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
    try {
      final importedCount = await widget.controller.saveFromQrCode(code);
      if (!mounted) return;

      final message = importedCount > 0
          ? context.l10n.accountsImported(importedCount)
          : context.l10n.accountsAlreadyImported;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(seconds: 3),
            content: Text(message),
          ),
        );

      Navigator.pop(context, importedCount > 0);
    } catch (e) {
      _done = false;
      _scanLineController.repeat();
      _framePulseController.repeat(reverse: true);
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentMaterialBanner()
          ..showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              backgroundColor: Colors.red.shade600,
              duration: const Duration(seconds: 3),
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.l10n.invalidQr('$e'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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

        return Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(onDetect: _onDetect),
            CamScanOverlay(
              scanAnimation: _scanLineController,
              framePulseAnimation: _framePulseController,
              scanBoxSize: scanBoxSize,
            ),
          ],
        );
      },
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
