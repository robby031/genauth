import 'package:flutter/material.dart';
import 'package:genauth/utils/l10n_extensions.dart';

class CamScanOverlay extends StatelessWidget {
  const CamScanOverlay({
    super.key,
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
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                context.l10n.scanQr,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
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
