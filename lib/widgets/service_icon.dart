import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../services/icon_service.dart';

class ServiceIcon extends StatelessWidget {
  final String issuer;
  final String label;

  const ServiceIcon({super.key, required this.issuer, required this.label});

  String get _letter {
    final src = issuer.isNotEmpty ? issuer : label;
    return src.isNotEmpty ? src[0].toUpperCase() : '?';
  }

  Color _color() {
    const palette = [
      Color(0xFF5C6BC0),
      Color(0xFF26A69A),
      Color(0xFFEF5350),
      Color(0xFFAB47BC),
      Color(0xFF42A5F5),
      Color(0xFFFF7043),
      Color(0xFF66BB6A),
      Color(0xFFEC407A),
    ];
    final seed = issuer + label;
    return palette[seed.codeUnits.fold(0, (a, b) => a + b) % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final url = IconService.faviconUrl(issuer);
    if (url != null) {
      return CachedNetworkImage(
        imageUrl: url,
        width: 40,
        height: 40,
        imageBuilder: (context, imageProvider) =>
            _NetworkAvatar(imageProvider: imageProvider),
        placeholder: (_, url) =>
            _LetterAvatar(letter: _letter, color: _color()),
        errorWidget: (_, url, error) =>
            _LetterAvatar(letter: _letter, color: _color()),
      );
    }
    return _LetterAvatar(letter: _letter, color: _color());
  }
}

class _NetworkAvatar extends StatelessWidget {
  final ImageProvider imageProvider;
  const _NetworkAvatar({required this.imageProvider});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        image: DecorationImage(image: imageProvider, fit: BoxFit.contain),
      ),
    );
  }
}

class _LetterAvatar extends StatelessWidget {
  final String letter;
  final Color color;
  const _LetterAvatar({required this.letter, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }
}
