import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../controllers/add_account_controller.dart';
import '../services/storage_service.dart';
import '../utils/l10n_extensions.dart';

class AddAccountScreen extends StatefulWidget {
  const AddAccountScreen({super.key});

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final AddAccountController _controller;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _controller = AddAccountController(storage: StorageService.instance);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.addAccount),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: context.l10n.scanQr),
            Tab(text: context.l10n.manualEntry),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _ScanTab(controller: _controller),
          _ManualTab(controller: _controller),
        ],
      ),
    );
  }
}

class _ScanTab extends StatefulWidget {
  const _ScanTab({required this.controller});

  final AddAccountController controller;

  @override
  State<_ScanTab> createState() => _ScanTabState();
}

class _ScanTabState extends State<_ScanTab> with TickerProviderStateMixin {
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
    if (code == null || !code.startsWith('otpauth://')) return;

    _done = true;
    _scanLineController.stop();
    _framePulseController.stop();
    try {
      await widget.controller.saveFromQrCode(code);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _done = false;
      _scanLineController.repeat();
      _framePulseController.repeat(reverse: true);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.invalidQr('$e'))));
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
            _ScanOverlay(
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

class _ScanOverlay extends StatelessWidget {
  const _ScanOverlay({
    required this.scanAnimation,
    required this.framePulseAnimation,
    required this.scanBoxSize,
  });

  final Animation<double> scanAnimation;
  final Animation<double> framePulseAnimation;
  final double scanBoxSize;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final left = (width - scanBoxSize) / 2;
        final top = (height - scanBoxSize) / 2;
        const overlayColor = Color.fromRGBO(0, 0, 0, 0.58);
        final accentColor = Theme.of(context).colorScheme.primary;

        return IgnorePointer(
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                right: 0,
                height: top,
                child: const ColoredBox(color: overlayColor),
              ),
              Positioned(
                left: 0,
                top: top,
                width: left,
                height: scanBoxSize,
                child: const ColoredBox(color: overlayColor),
              ),
              Positioned(
                right: 0,
                top: top,
                width: left,
                height: scanBoxSize,
                child: const ColoredBox(color: overlayColor),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: top + scanBoxSize,
                bottom: 0,
                child: const ColoredBox(color: overlayColor),
              ),
              Positioned(
                left: left,
                top: top,
                width: scanBoxSize,
                height: scanBoxSize,
                child: AnimatedBuilder(
                  animation: framePulseAnimation,
                  builder: (context, child) {
                    final borderColor = Color.lerp(
                      accentColor.withValues(alpha: 0.65),
                      accentColor,
                      0.35 + (0.45 * framePulseAnimation.value),
                    );

                    return DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: borderColor!, width: 2),
                        borderRadius: BorderRadius.circular(18),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                left: left,
                top: top,
                width: scanBoxSize,
                height: scanBoxSize,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        accentColor.withValues(alpha: 0.05),
                        Colors.transparent,
                        accentColor.withValues(alpha: 0.03),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: left,
                top: top,
                width: scanBoxSize,
                height: scanBoxSize,
                child: _CornerAccent(
                  color: accentColor.withValues(alpha: 0.95),
                ),
              ),
              AnimatedBuilder(
                animation: scanAnimation,
                builder: (context, child) {
                  final lineY =
                      top + 8 + (scanBoxSize - 16) * scanAnimation.value;
                  return Positioned(
                    left: left + 10,
                    right: left + 10,
                    top: lineY,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            accentColor,
                            Colors.transparent,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.7),
                            blurRadius: 16,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                left: left,
                right: left,
                top: top + scanBoxSize + 16,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.qr_code_scanner,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            context.l10n.scanQr,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CornerAccent extends StatelessWidget {
  const _CornerAccent({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Stack(
        children: [
          _corner(alignment: Alignment.topLeft, left: true, top: true),
          _corner(alignment: Alignment.topRight, right: true, top: true),
          _corner(alignment: Alignment.bottomLeft, left: true, bottom: true),
          _corner(alignment: Alignment.bottomRight, right: true, bottom: true),
        ],
      ),
    );
  }

  Widget _corner({
    required Alignment alignment,
    bool left = false,
    bool right = false,
    bool top = false,
    bool bottom = false,
  }) {
    return Align(
      alignment: alignment,
      child: SizedBox(
        width: 28,
        height: 28,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              left: left ? BorderSide(color: color, width: 3) : BorderSide.none,
              right: right
                  ? BorderSide(color: color, width: 3)
                  : BorderSide.none,
              top: top ? BorderSide(color: color, width: 3) : BorderSide.none,
              bottom: bottom
                  ? BorderSide(color: color, width: 3)
                  : BorderSide.none,
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _labelCtrl,
              decoration: InputDecoration(labelText: context.l10n.accountLabel),
              validator: (v) => v == null || v.trim().isEmpty
                  ? context.l10n.requiredField
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _issuerCtrl,
              decoration: InputDecoration(labelText: context.l10n.issuerLabel),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _secretCtrl,
                    decoration: InputDecoration(
                      labelText: context.l10n.secretKeyLabel,
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? context.l10n.requiredField
                        : null,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.autorenew),
                  tooltip: context.l10n.generateNewSecret,
                  onPressed: _generateSecret,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _algorithm,
                    decoration: InputDecoration(
                      labelText: context.l10n.algorithm,
                    ),
                    items: ['SHA1', 'SHA256', 'SHA512']
                        .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                        .toList(),
                    onChanged: (v) => setState(() => _algorithm = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _digits,
                    decoration: InputDecoration(labelText: context.l10n.digits),
                    items: [6, 7, 8]
                        .map(
                          (d) => DropdownMenuItem(value: d, child: Text('$d')),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _digits = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: Text(context.l10n.hotpCounterBased),
              subtitle: Text(context.l10n.defaultTotpTimeBased),
              value: _isHotp,
              onChanged: (v) => setState(() => _isHotp = v),
              contentPadding: EdgeInsets.zero,
            ),
            if (!_isHotp) ...[
              const SizedBox(height: 4),
              DropdownButtonFormField<int>(
                initialValue: _period,
                decoration: InputDecoration(
                  labelText: context.l10n.periodSeconds,
                ),
                items: [15, 30, 60, 90, 120]
                    .map(
                      (p) => DropdownMenuItem(value: p, child: Text('${p}s')),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _period = v!),
              ),
            ],
            const SizedBox(height: 28),
            AnimatedBuilder(
              animation: widget.controller,
              builder: (context, child) {
                return FilledButton(
                  onPressed: widget.controller.saving ? null : _save,
                  child: widget.controller.saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(context.l10n.addAccount),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
