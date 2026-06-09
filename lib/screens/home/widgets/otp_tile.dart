import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:genauth/models/otp_account.dart';
import 'package:genauth/providers/second_tick_provider.dart';
import 'package:genauth/services/audit_log_service.dart';
import 'package:genauth/services/clipboard_security_service.dart';
import 'package:genauth/services/otp_service.dart';
import 'package:genauth/widgets/service_icon.dart';
import 'package:genauth/widgets/snack_message.dart';
import 'package:genauth/widgets/tag_editor_sheet.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:genauth/utils/l10n_extensions.dart';

class OtpTile extends StatefulWidget {
  final int? reorderIndex;
  final OtpAccount account;
  final String code;
  final VoidCallback onDelete;
  final VoidCallback? onHotpIncrement;
  final bool showDragHandle;
  final void Function(List<String> tags)? onEditTags;

  const OtpTile({
    super.key,
    this.reorderIndex,
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

  bool _hasManualDomainMapping(List<String> tags) {
    for (final rawTag in tags) {
      final tag = rawTag.trim();
      if (tag.isEmpty) continue;

      final lower = tag.toLowerCase();
      if (lower.startsWith('domain:') ||
          lower.startsWith('host:') ||
          lower.startsWith('site:') ||
          lower.startsWith('web:')) {
        final mapped = tag.substring(tag.indexOf(':') + 1).trim();
        if (mapped.isNotEmpty) {
          return true;
        }
      }
    }
    return false;
  }

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

  Future<void> _onTap() async {
    await ClipboardSecurityService.instance.copyOtp(
      code: widget.code,
      period: widget.account.period,
      isHotp: widget.account.isHotp,
    );
    await AuditLogService.instance.log(
      'otp_code_copied',
      metadata: {
        'accountId': widget.account.id,
        'issuer': widget.account.issuer,
        'label': widget.account.label,
        'isHotp': widget.account.isHotp,
        'period': widget.account.period,
      },
    );
    setState(() => _revealed = true);
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) setState(() => _revealed = false);
    });
    if (!mounted) return;
    SnackMessage.show(
      context,
      context.l10n.codeCopied,
      icon: Icons.check_circle_outline,
      backgroundColor: Colors.green.shade600,
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
    final hasDomainMapping = _hasManualDomainMapping(widget.account.tags);
    final subtitle = widget.account.issuer.isNotEmpty
        ? '${widget.account.issuer} · ${widget.account.label}'
        : widget.account.label;
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
      child: Stack(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 6,
            ),
            horizontalTitleGap: 12,
            minLeadingWidth: 40,
            minVerticalPadding: 0,
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
              subtitle,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 12,
                overflow: TextOverflow.ellipsis,
                height: 1.25,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Tooltip(
                  message: hasDomainMapping
                      ? context.l10n.autofillDomainMappedStatus
                      : context.l10n.autofillDomainNotMappedStatus,
                  child: Icon(
                    hasDomainMapping
                        ? Icons.domain_verification_outlined
                        : Icons.domain_disabled_outlined,
                    size: 18,
                    color: hasDomainMapping
                        ? Colors.green.shade600
                        : scheme.outline,
                  ),
                ),
                const SizedBox(width: 10),
                if (widget.account.isHotp)
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: context.l10n.nextCode,
                    onPressed: widget.onHotpIncrement,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 22,
                      height: 22,
                    ),
                    splashRadius: 18,
                  )
                else
                  _TotpProgress(period: widget.account.period),
                if (widget.showDragHandle) ...[
                  const SizedBox(width: 10),
                  ReorderableDragStartListener(
                    index: widget.reorderIndex ?? 0,
                    child: Icon(
                      Icons.drag_indicator,
                      color: scheme.onSurface.withValues(alpha: 0.3),
                      size: 20,
                    ),
                  ),
                ],
              ],
            ),
            onTap: _onTap,
          ),
          if (widget.account.tags.isNotEmpty)
            Positioned(
              top: 8,
              left: 8,
              child: _TagCountBadge(
                count: widget.account.tags.length,
                scheme: scheme,
              ),
            ),
        ],
      ),
    );
  }
}

class _TagCountBadge extends StatelessWidget {
  final int count;
  final ColorScheme scheme;

  const _TagCountBadge({required this.count, required this.scheme});

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : '$count';
    return IgnorePointer(
      child: Container(
        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        decoration: BoxDecoration(
          color: scheme.primaryFixed.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            color: scheme.onPrimaryFixed,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}

class _TotpProgress extends ConsumerWidget {
  final int period;
  const _TotpProgress({required this.period});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(secondTickProvider);

    final remaining = OtpService.remainingSeconds(period);
    final urgent = remaining <= 5;
    return SizedBox(
      width: 20,
      height: 20,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: OtpService.progress(period),
            strokeWidth: 3,
            color: urgent ? Colors.red : Theme.of(context).colorScheme.primary,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest,
          ),
          Text(
            '$remaining',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: urgent ? Colors.red : null,
            ),
          ),
        ],
      ),
    );
  }
}
