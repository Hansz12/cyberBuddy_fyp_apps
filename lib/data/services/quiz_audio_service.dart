import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Low-volume, offline cyber-focus music used only while a quiz is in progress.
///
/// The WAV loop is generated in memory, so the app does not need to bundle or
/// stream a copyrighted music file. It is intentionally soft and can be muted.
class QuizAudioService {
  static const _mutePreferenceKey = 'quiz_ambient_audio_muted';

  final AudioPlayer _player = AudioPlayer();
  late final Uint8List _ambientLoop = _buildAmbientLoop();

  bool _isMuted = false;
  bool _isPlaying = false;
  String? _ambientFilePath;

  bool get isMuted => _isMuted;

  Future<void> loadPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isMuted = prefs.getBool(_mutePreferenceKey) ?? false;
    } catch (_) {
      _isMuted = false;
    }
  }

  Future<void> start() async {
    if (_isMuted || _isPlaying) return;

    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(0.18);
      final source = await _ambientSource();
      await _player.play(source);
      _isPlaying = true;
    } catch (error) {
      // Audio is optional: a playback limitation must never interrupt a quiz.
      debugPrint('Quiz ambient audio could not start: $error');
      _isPlaying = false;
    }
  }

  Future<void> setMuted(bool muted) async {
    _isMuted = muted;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_mutePreferenceKey, muted);
    } catch (_) {}

    if (muted) {
      await stop();
    } else {
      await start();
    }
  }

  Future<void> stop() async {
    if (!_isPlaying) return;

    try {
      await _player.stop();
    } catch (_) {}
    _isPlaying = false;
  }

  Future<void> dispose() async {
    try {
      await _player.dispose();
    } catch (_) {}
  }

  Future<DeviceFileSource> _ambientSource() async {
    if (_ambientFilePath != null) {
      return DeviceFileSource(_ambientFilePath!, mimeType: 'audio/wav');
    }

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}${Platform.pathSeparator}quiz_ambient.wav');

    final shouldWrite =
        !(await file.exists()) || (await file.length()) != _ambientLoop.length;
    if (shouldWrite) {
      await file.writeAsBytes(_ambientLoop, flush: true);
    }

    _ambientFilePath = file.path;
    return DeviceFileSource(file.path, mimeType: 'audio/wav');
  }

  Uint8List _buildAmbientLoop() {
    // A calm, minor-key arpeggio is intentionally used instead of a static
    // drone. It feels game-like, but leaves enough space for users to read.
    const sampleRate = 16000;
    const durationSeconds = 10;
    const sampleCount = sampleRate * durationSeconds;
    const headerSize = 44;
    const bitsPerSample = 16;
    const bytesPerSample = bitsPerSample ~/ 8;
    final dataLength = sampleCount * bytesPerSample;
    final bytes = Uint8List(headerSize + dataLength);
    final data = ByteData.sublistView(bytes);

    void writeAscii(int offset, String value) {
      for (var index = 0; index < value.length; index++) {
        bytes[offset + index] = value.codeUnitAt(index);
      }
    }

    writeAscii(0, 'RIFF');
    data.setUint32(4, 36 + dataLength, Endian.little);
    writeAscii(8, 'WAVE');
    writeAscii(12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, 1, Endian.little);
    data.setUint32(24, sampleRate, Endian.little);
    data.setUint32(28, sampleRate * bytesPerSample, Endian.little);
    data.setUint16(32, bytesPerSample, Endian.little);
    data.setUint16(34, bitsPerSample, Endian.little);
    writeAscii(36, 'data');
    data.setUint32(40, dataLength, Endian.little);

    const beatSeconds = 0.625; // 96 BPM
    const stepSeconds = beatSeconds / 2;
    const chordSeconds = beatSeconds * 4;
    const roots = [146.83, 130.81, 174.61, 130.81]; // Dm, Cm, F, Cm
    const arpeggioMultipliers = [
      1.0,
      1.4983,
      1.7818,
      2.2449,
      1.7818,
      1.4983,
      2.9966,
      2.2449,
    ];

    for (var index = 0; index < sampleCount; index++) {
      final seconds = index / sampleRate;
      final beatPosition = (seconds % beatSeconds) / beatSeconds;
      final chordPosition = (seconds % chordSeconds) / chordSeconds;
      final chordIndex = (seconds / chordSeconds).floor() % roots.length;
      final stepIndex = (seconds / stepSeconds).floor() % arpeggioMultipliers.length;
      final stepPosition = (seconds % stepSeconds) / stepSeconds;
      final root = roots[chordIndex];
      final note = root * arpeggioMultipliers[stepIndex];

      final pluckEnvelope = math.exp(-stepPosition * 5.8);
      final chordEnvelope = math.sin(math.pi * chordPosition);
      final loopPosition = index / (sampleCount - 1);
      final loopEnvelope = (loopPosition * 14)
          .clamp(0.0, 1.0)
          .toDouble() *
          ((1 - loopPosition) * 14).clamp(0.0, 1.0).toDouble();

      final melody = _triangleWave(note, seconds) * 0.20 * pluckEnvelope;
      final shimmer =
          math.sin(2 * math.pi * note * 2 * seconds) * 0.035 * pluckEnvelope;
      final pad =
          (math.sin(2 * math.pi * root * seconds) * 0.055 +
              math.sin(2 * math.pi * root * 1.4983 * seconds) * 0.030) *
          chordEnvelope;
      final bass = math.sin(2 * math.pi * (root / 2) * seconds) *
          (0.070 * (0.45 + (0.55 * math.exp(-beatPosition * 3))));
      final pulse = math.sin(2 * math.pi * (74 - (38 * beatPosition)) * beatPosition) *
          (0.055 * math.exp(-beatPosition * 9));
      final sample =
          ((melody + shimmer + pad + bass + pulse) * loopEnvelope * 32767)
          .round()
          .clamp(-32768, 32767)
          .toInt();

      data.setInt16(headerSize + (index * bytesPerSample), sample, Endian.little);
    }

    return bytes;
  }

  double _triangleWave(double frequency, double seconds) {
    final phase = (frequency * seconds) % 1;
    return 1 - (4 * (phase - 0.5).abs());
  }
}
