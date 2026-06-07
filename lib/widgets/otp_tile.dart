import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/otp_account.dart';
import '../services/otp_service.dart';
import '../widgets/service_icon.dart';
import '../widgets/tag_editor_sheet.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../utils/l10n_extensions.dart';

class OtpTile extends StatefulWidget {
  final OtpAccount account;
  final String code;
  final VoidCallback onDelete;
  final VoidCallback? onHotpIncrement;
  final bool showDragHandle;
  final void Function(List<String> tags)? onEditTags;

  const OtpTile({
    super.key,
    required this.account,
    required this.code,
    required this.onDelete,
    this.onHotpIncrement,
    this.showDragHandle = false,
    this.onEditTags,
  });

  @override
  State<OtpTile> createState() => _OtpTileState();
}

class _OtpTileState extends State<OtpTile> {
  bool _revealed = false;
  Timer? _hideTimer;

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(OtpTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.account.id != widget.account.id) {
      _hideTimer?.cancel();
      _revealed = false;
    }
  }

  void _onTap() {
    Clipboard.setData(ClipboardData(text: widget.code));
    setState(() => _revealed = true);
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) setState(() => _revealed = false);
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentMaterialBanner()
      ..showSnackBar(
        SnackBar(
          content: Text(context.l10n.codeCopied),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
  }

  Future<void> _openTagEditor(BuildContext context) async {
    final name = widget.account.issuer.isNotEmpty
        ? widget.account.issuer
        : widget.account.label;
    final updated = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) =>
          TagEditorSheet(accountName: name, initialTags: widget.account.tags),
    );
    if (updated != null) widget.onEditTags?.call(updated);
  }

  String get _maskedCode {
    final len = widget.code.replaceAll(' ', '').length;
    if (len == 6) return '••• •••';
    if (len == 8) return '•••• ••••';
    return '•' * len;
  }

  String get _displayCode {
    final c = widget.code;
    if (c.length == 6) return '${c.substring(0, 3)} ${c.substring(3)}';
    if (c.length == 8) return '${c.substring(0, 4)} ${c.substring(4)}';
    return c;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Slidable(
      key: ValueKey(widget.account.id),
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.20,
        children: [
          SlidableAction(
            onPressed: _openTagEditor,
            backgroundColor: scheme.primary,
            foregroundColor: scheme.onPrimary,
            icon: Icons.label_outline,
            label: context.l10n.tags,
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.18,
        children: [
          SlidableAction(
            autoClose: false,
            onPressed: (context) async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(context.l10n.deleteAccount),
                  content: Text(
                    context.l10n.removeAccount(
                      widget.account.issuer.isNotEmpty
                          ? widget.account.issuer
                          : widget.account.label,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(context.l10n.cancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: Text(context.l10n.delete),
                    ),
                  ],
                ),
              );
              if (confirm == true) widget.onDelete();
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: context.l10n.delete,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: ServiceIcon(
              issuer: widget.account.issuer,
              label: widget.account.label,
            ),
            title: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Align(
                key: ValueKey(_revealed),
                alignment: Alignment.centerLeft,
                child: Text(
                  _revealed ? _displayCode : _maskedCode,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                    color: _revealed
                        ? null
                        : scheme.onSurface.withValues(alpha: 0.35),
                  ),
                ),
              ),
            ),
            subtitle: Text(
              widget.account.issuer.isNotEmpty
                  ? '${widget.account.issuer} · ${widget.account.label}'
                  : widget.account.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.account.isHotp)
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: context.l10n.nextCode,
                    onPressed: widget.onHotpIncrement,
                  )
                else
                  _TotpProgress(period: widget.account.period),
                if (widget.showDragHandle) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.drag_handle,
                    color: scheme.onSurface.withValues(alpha: 0.3),
                    size: 20,
                  ),
                ],
              ],
            ),
            onTap: _onTap,
          ),
          if (widget.account.tags.isNotEmpty)
            _TagChipsRow(tags: widget.account.tags, scheme: scheme),
        ],
      ),
    );
  }
}

class _TagChipsRow extends StatelessWidget {
  final List<String> tags;
  final ColorScheme scheme;

  const _TagChipsRow({required this.tags, required this.scheme});

  @override
  Widget build(BuildContext context) {
    final visible = tags.take(3).toList();
    final overflow = tags.length - visible.length;
    return Padding(
      padding: const EdgeInsets.only(left: 72, right: 16, bottom: 8),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          for (final tag in visible)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                tag,
                style: TextStyle(
                  fontSize: 11,
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          if (overflow > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '+$overflow',
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }
}

class _TotpProgress extends StatefulWidget {
  final int period;
  const _TotpProgress({required this.period});

  @override
  State<_TotpProgress> createState() => _TotpProgressState();
}

class _TotpProgressState extends State<_TotpProgress> {
  late int _remaining;

  @override
  void initState() {
    super.initState();
    _tick();
    Stream.periodic(const Duration(seconds: 1)).listen((_) {
      if (mounted) setState(_tick);
    });
  }

  void _tick() => _remaining = OtpService.remainingSeconds(widget.period);

  @override
  Widget build(BuildContext context) {
    final urgent = _remaining <= 5;
    return SizedBox(
      width: 32,
      height: 32,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: OtpService.progress(widget.period),
            strokeWidth: 3,
            color: urgent ? Colors.red : Theme.of(context).colorScheme.primary,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest,
          ),
          Text(
            '$_remaining',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: urgent ? Colors.red : null,
            ),
          ),
        ],
      ),
    );
  }
}
