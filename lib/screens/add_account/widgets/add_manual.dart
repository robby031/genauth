import 'dart:async';

import 'package:flutter/material.dart';
import 'package:genauth/controllers/add_account_controller.dart';
import 'package:genauth/utils/l10n_extensions.dart';

class ManualAdd extends StatefulWidget {
  const ManualAdd({super.key, required this.controller});

  final AddAccountController controller;

  @override
  State<ManualAdd> createState() => _ManualAddState();
}

class _ManualAddState extends State<ManualAdd> {
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
