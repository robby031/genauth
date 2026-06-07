import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/otp_account.dart';
import '../services/storage_service.dart';
import '../services/otp_service.dart';

class AddAccountScreen extends StatefulWidget {
  const AddAccountScreen({super.key});

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add account'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Scan QR'),
            Tab(text: 'Manual entry'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [_ScanTab(), _ManualTab()],
      ),
    );
  }
}

// ---- QR scanner tab ----

class _ScanTab extends StatefulWidget {
  const _ScanTab();

  @override
  State<_ScanTab> createState() => _ScanTabState();
}

class _ScanTabState extends State<_ScanTab> {
  bool _done = false;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_done) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || !code.startsWith('otpauth://')) return;

    _done = true;
    try {
      final account = OtpAccount.fromUri(code);
      await StorageService().addAccount(account);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _done = false;
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Invalid QR: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MobileScanner(onDetect: _onDetect);
  }
}

// ---- Manual entry tab ----

class _ManualTab extends StatefulWidget {
  const _ManualTab();

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
  bool _saving = false;

  @override
  void dispose() {
    _labelCtrl.dispose();
    _issuerCtrl.dispose();
    _secretCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final account = OtpAccount(
      id: OtpAccount.newId(),
      label: _labelCtrl.text.trim(),
      issuer: _issuerCtrl.text.trim(),
      secretB32: _secretCtrl.text.trim().toUpperCase().replaceAll(' ', ''),
      algorithm: _algorithm,
      digits: _digits,
      period: _period,
      isHotp: _isHotp,
    );

    await StorageService().addAccount(account);
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _generateSecret() async {
    final s = await OtpService.generateSecret();
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
              decoration: const InputDecoration(
                labelText: 'Account (e.g. user@example.com)',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _issuerCtrl,
              decoration: const InputDecoration(
                labelText: 'Issuer (e.g. Google)',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _secretCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Secret key (Base32)',
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.autorenew),
                  tooltip: 'Generate new secret',
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
                    decoration: const InputDecoration(labelText: 'Algorithm'),
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
                    decoration: const InputDecoration(labelText: 'Digits'),
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
              title: const Text('HOTP (counter-based)'),
              subtitle: const Text('Default is TOTP (time-based)'),
              value: _isHotp,
              onChanged: (v) => setState(() => _isHotp = v),
              contentPadding: EdgeInsets.zero,
            ),
            if (!_isHotp) ...[
              const SizedBox(height: 4),
              DropdownButtonFormField<int>(
                initialValue: _period,
                decoration: const InputDecoration(
                  labelText: 'Period (seconds)',
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
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Add account'),
            ),
          ],
        ),
      ),
    );
  }
}
