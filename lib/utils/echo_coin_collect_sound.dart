import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../services/photo_wall_settings_service.dart';

/// 成就回响币收集音效：金币落入钱袋（合成 WAV）。
abstract final class EchoCoinCollectSound {
  static final AudioPlayer _burstPlayer = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop);
  static final AudioPlayer _finishPlayer = AudioPlayer()
    ..setReleaseMode(ReleaseMode.stop);
  static final List<AudioPlayer> _landPlayers = List.generate(
    3,
    (_) => AudioPlayer()..setReleaseMode(ReleaseMode.stop),
  );
  static var _landPlayerCursor = 0;

  static Future<void> playBurst() async {
    if (!_enabled) return;
    if (kIsWeb) {
      await SystemSound.play(SystemSoundType.click);
      return;
    }
    try {
      await _burstPlayer.play(
        BytesSource(_burstWav, mimeType: 'audio/wav'),
        volume: 0.22,
      );
    } catch (e) {
      debugPrint('Echo: coin burst sound failed: $e');
    }
  }

  static Future<void> playLand({int index = 0}) async {
    if (!_enabled) return;
    if (kIsWeb) return;
    try {
      final player = _landPlayers[_landPlayerCursor % _landPlayers.length];
      _landPlayerCursor++;
      await player.play(
        BytesSource(_landWavs[index % _landWavs.length], mimeType: 'audio/wav'),
        volume: (0.34 + (index % 3) * 0.04).clamp(0.0, 0.46),
      );
    } catch (e) {
      debugPrint('Echo: coin land sound failed: $e');
    }
  }

  static Future<void> playFinish() async {
    if (!_enabled) return;
    if (kIsWeb) {
      await SystemSound.play(SystemSoundType.click);
      return;
    }
    try {
      await _finishPlayer.play(
        BytesSource(_finishWav, mimeType: 'audio/wav'),
        volume: 0.5,
      );
    } catch (e) {
      debugPrint('Echo: coin finish sound failed: $e');
      await HapticFeedback.mediumImpact();
    }
  }

  static bool get _enabled =>
      PhotoWallSettingsService.instance.pinSoundEnabled;

  static Uint8List _synthWav({
    required int milliseconds,
    required double Function(double t, Random rng) sampleAt,
    int seed = 7,
  }) {
    const sampleRate = 22050;
    final sampleCount = (sampleRate * milliseconds / 1000).round();
    final byteRate = sampleRate * 2;
    final dataSize = sampleCount * 2;
    final buffer = ByteData(44 + dataSize);

    buffer.setUint8(0, 0x52);
    buffer.setUint8(1, 0x49);
    buffer.setUint8(2, 0x46);
    buffer.setUint8(3, 0x46);
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

    final rng = Random(seed);
    for (var i = 0; i < sampleCount; i++) {
      final t = i / sampleRate;
      final sample = (sampleAt(t, rng) * 32767).round();
      buffer.setInt16(
        44 + i * 2,
        sample.clamp(-32768, 32767),
        Endian.little,
      );
    }

    return buffer.buffer.asUint8List();
  }

  /// 钱袋口轻微摩擦（开场）。
  static final _burstWav = _synthWav(
    milliseconds: 70,
    seed: 3,
    sampleAt: (t, rng) {
      final env = exp(-t * 24);
      final rustle = (rng.nextDouble() - 0.5) * 0.22;
      final body = sin(2 * pi * 180 * t) * 0.12;
      return (rustle + body) * env * 0.42;
    },
  );

  static Uint8List _coinInBagWav({required double pitch}) {
    return _synthWav(
      milliseconds: 120,
      seed: (pitch * 1000).round(),
      sampleAt: (t, rng) {
        var wave = 0.0;
        final pingEnv = exp(-t * 90);
        if (t < 0.03) {
          wave += sin(2 * pi * 2200 * pitch * t) * 0.42 * pingEnv;
          wave += sin(2 * pi * 3100 * pitch * t) * 0.18 * pingEnv;
        }
        if (t > 0.01) {
          final thudT = t - 0.01;
          final thudEnv = exp(-thudT * 26);
          wave += sin(2 * pi * 165 * pitch * thudT) * 0.5 * thudEnv;
          wave += sin(2 * pi * 88 * pitch * thudT) * 0.28 * thudEnv;
        }
        wave += (rng.nextDouble() - 0.5) * exp(-t * 20) * 0.1;
        return wave.clamp(-0.9, 0.9);
      },
    );
  }

  static final _landWavs = [
    _coinInBagWav(pitch: 0.94),
    _coinInBagWav(pitch: 1.0),
    _coinInBagWav(pitch: 1.06),
    _coinInBagWav(pitch: 1.12),
  ];

  /// 最后一枚落袋 + 钱袋轻晃。
  static final _finishWav = _synthWav(
    milliseconds: 200,
    seed: 19,
    sampleAt: (t, rng) {
      var wave = 0.0;
      for (final hit in [0.0, 0.045, 0.09]) {
        if (t < hit) continue;
        final local = t - hit;
        final env = exp(-local * 22);
        wave += sin(2 * pi * 2100 * local) * 0.2 * env;
        wave += sin(2 * pi * 140 * local) * 0.38 * env;
      }
      wave += sin(2 * pi * 72 * t) * exp(-t * 7) * 0.22;
      wave += (rng.nextDouble() - 0.5) * exp(-t * 14) * 0.08;
      return wave.clamp(-0.95, 0.95);
    },
  );
}
