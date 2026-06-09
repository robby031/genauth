import 'package:flutter/material.dart';
import 'package:genauth/utils/l10n_extensions.dart';
import 'widgets/add_account_chooser.dart';
import 'package:genauth/widgets/scan_qr.dart';
import 'widgets/add_manual.dart';

class AddAccountScreen extends StatefulWidget {
  const AddAccountScreen({super.key, this.importMode = false});

  final bool importMode;

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

enum _AddAccountMode { chooser, scan, manual }

class _AddAccountScreenState extends State<AddAccountScreen> {
  late _AddAccountMode _mode;

  @override
  void initState() {
    super.initState();
    _mode = widget.importMode ? _AddAccountMode.scan : _AddAccountMode.chooser;
  }

  void _openMode(_AddAccountMode mode) {
    setState(() => _mode = mode);
  }

  void _backToChooser() {
    if (_mode == _AddAccountMode.chooser || widget.importMode) {
      Navigator.pop(context);
      return;
    }
    setState(() => _mode = _AddAccountMode.chooser);
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (_mode) {
      _AddAccountMode.scan =>
        widget.importMode
            ? context.l10n.googleAuthImportAction
            : context.l10n.scanQr,
      _AddAccountMode.manual => context.l10n.manualEntry,
      _AddAccountMode.chooser => context.l10n.addAccount,
    };

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        centerTitle: false,
        leading: (_mode != _AddAccountMode.chooser || widget.importMode)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _backToChooser,
              )
            : null,
        title: Text(title, style: const TextStyle(fontSize: 16)),
      ),
      body: switch (_mode) {
        _AddAccountMode.scan => const ScanQr(isActive: true),
        _AddAccountMode.manual => const ManualAdd(),
        _AddAccountMode.chooser => AddAccountChooser(
          onScanSelected: () => _openMode(_AddAccountMode.scan),
          onManualSelected: () => _openMode(_AddAccountMode.manual),
        ),
      },
    );
  }
}
