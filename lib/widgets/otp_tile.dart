import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/otp_account.dart';
import '../services/otp_service.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class OtpTile extends StatelessWidget {
  final OtpAccount account;
  final String code;
  final VoidCallback onDelete;
  final VoidCallback? onHotpIncrement;

  const OtpTile({
    super.key,
    required this.account,
    required this.code,
    required this.onDelete,
    this.onHotpIncrement,
  });

  String get _displayCode {
    if (code.length == 6) return '${code.substring(0, 3)} ${code.substring(3)}';
    if (code.length == 8) return '${code.substring(0, 4)} ${code.substring(4)}';
    return code;
  }

  String get _avatarLabel {
    final src = account.issuer.isNotEmpty ? account.issuer : account.label;
    return src.isNotEmpty ? src[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: ValueKey(account.id),
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
                  title: const Text('Delete account'),
                  content: Text(
                    'Remove ${account.issuer.isNotEmpty ? account.issuer : account.label}?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                onDelete();
              }
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _avatarColor(account.issuer + account.label),
          child: Text(
            _avatarLabel,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          _displayCode,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
          ),
        ),
        subtitle: Text(
          account.issuer.isNotEmpty
              ? '${account.issuer} · ${account.label}'
              : account.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: account.isHotp
            ? IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Next code',
                onPressed: onHotpIncrement,
              )
            : _TotpProgress(period: account.period),
        onTap: () {
          Clipboard.setData(ClipboardData(text: code));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Code copied'),
              duration: Duration(seconds: 1),
            ),
          );
        },
      ),
    );
  }

  Color _avatarColor(String seed) {
    const colors = [
      Color(0xFF5C6BC0),
      Color(0xFF26A69A),
      Color(0xFFEF5350),
      Color(0xFFAB47BC),
      Color(0xFF42A5F5),
      Color(0xFFFF7043),
      Color(0xFF66BB6A),
      Color(0xFFEC407A),
    ];
    return colors[seed.codeUnits.fold(0, (a, b) => a + b) % colors.length];
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
