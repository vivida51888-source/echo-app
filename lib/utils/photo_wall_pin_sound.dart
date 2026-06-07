import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/photo_wall_material.dart';
import '../services/photo_wall_settings_service.dart';

/// 钉墙 / 胶带音效（可关）。
abstract final class PhotoWallPinSound {
  static final AudioPlayer _player = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop);

  static Future<void> play(PhotoWallMaterial material) async {
    if (!PhotoWallSettingsService.instance.pinSoundEnabled) return;
    if (kIsWeb) {
      await SystemSound.play(SystemSoundType.click);
      return;
    }

    try {
      await _player.stop();
      await _player.play(
        BytesSource(
          material.usesMagnet || material.usesClip || material.usesTape
              ? _tapeWav
              : _pinWav,
          mimeType: 'audio/wav',
        ),
        volume: material.usesMagnet ||
                material.usesClip ||
                material.usesTape
            ? 0.42
            : 0.55,
      );
    } catch (e) {
      debugPrint('Echo: pin sound failed: $e');
      await HapticFeedback.lightImpact();
    }
  }

  static Uint8List _synthWav({
    required double frequency,
    required int milliseconds,
    required double decay,
  }) {
    const sampleRate = 22050;
    final sampleCount = (sampleRate * milliseconds / 1000).round();
    final byteRate = sampleRate * 2;
    final dataSize = sampleCount * 2;
    final buffer = ByteData(44 + dataSize);

    buffer.setUint8(0, 0x52); // R
    buffer.setUint8(1, 0x49); // I
    buffer.setUint8(2, 0x46); // F
    buffer.setUint8(3, 0x46); // F
    buffer.setUint32(4, 36 + dataSize, Endian.little);
    buffer.setUint8(8, 0x57);
    buffer.setUint8(9, 0x41);
    buffer.setUint8(10, 0x56);
    buffer.setUint8(11, 0x45);
    buffer.setUint8(12, 0x66);
    buffer.setUint8(13, 0x6d);
    buffer.setUint8(14, 0x74);
    buffer.setUint8(15, 0x20);
    buffer.setUint32(16, 16, Endian.little);
    buffer.setUint16(20, 1, Endian.little);
    buffer.setUint16(22, 1, Endian.little);
    buffer.setUint32(24, sampleRate, Endian.little);
    buffer.setUint32(28, byteRate, Endian.little);
    buffer.setUint16(32, 2, Endian.little);
    buffer.setUint16(34, 16, Endian.little);
    buffer.setUint8(36, 0x64);
    buffer.setUint8(37, 0x61);
    buffer.setUint8(38, 0x74);
    buffer.setUint8(39, 0x61);
    buffer.setUint32(40, dataSize, Endian.little);

    for (var i = 0; i < sampleCount; i++) {
      final t = i / sampleRate;
      final envelope = exp(-t * decay);
      final noise = (Random(7).nextDouble() - 0.5) * 0.08;
      final wave = sin(2 * pi * frequency * t);
      final sample = ((wave + noise) * envelope * 0.42 * 32767).round();
      buffer.setInt16(
        44 + i * 2,
        sample.clamp(-32768, 32767),
        Endian.little,
      );
    }

    return buffer.buffer.asUint8List();
  }

  static final _ejectWav = _synthWav(
    frequency: 140,
    milliseconds: 220,
    decay: 6,
  );

  /// 拍立得「吐出」时的滋滋声。
  static Future<void> playEject() async {
    if (!PhotoWallSettingsService.instance.pinSoundEnabled) return;
    if (kIsWeb) {
      await SystemSound.play(SystemSoundType.click);
      return;
    }

    try {
      await _player.stop();
      await _player.play(
        BytesSource(_ejectWav, mimeType: 'audio/wav'),
        volume: 0.62,
      );
    } catch (e) {
      debugPrint('Echo: eject sound failed: $e');
      await HapticFeedback.mediumImpact();
    }
  }

  static final _pinWav = _synthWav(
    frequency: 220,
    milliseconds: 70,
    decay: 38,
  );

  static final _tapeWav = _synthWav(
    frequency: 520,
    milliseconds: 45,
    decay: 52,
  );
}
