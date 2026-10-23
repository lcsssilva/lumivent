import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../lighting/lighting.dart';

class EffectThumbnail extends StatelessWidget {
  const EffectThumbnail({super.key, required this.effect, required this.bytes});
  final InstalledEffect effect;
  final Future<Uint8List?>? bytes;

  @override
  Widget build(BuildContext context) {
    final future = bytes;
    if (future != null) {
      return FutureBuilder<Uint8List?>(
        future: future,
        builder: (context, snapshot) {
          final data = snapshot.data;
          if (data != null) {
            return Image.memory(
              data,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              // A frame is 320×200: keep it crisp.
              filterQuality: FilterQuality.medium,
            );
          }
          return _placeholder();
        },
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    final hash = effect.id.hashCode.abs();
    final hue = (hash % 360).toDouble();
    final start = HSVColor.fromAHSV(1, hue, .55, .38).toColor();
    final end = HSVColor.fromAHSV(1, (hue + 55) % 360, .65, .18).toColor();
    final initial = effect.title.trim().isEmpty
        ? '?'
        : effect.title.trim().characters.first.toUpperCase();
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [end, start],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: .82),
          ),
        ),
      ),
    );
  }
}
