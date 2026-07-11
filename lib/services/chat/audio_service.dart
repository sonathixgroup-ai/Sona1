import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;

// Import conditionnel pour le Web
import 'dart:html' if (dart.library.html) 'dart:html' as html;

/// Service pour l'enregistrement, la lecture et l'upload de messages audio.
class AudioService {
  final SupabaseClient _supabase;
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  String? _currentRecordingPath;
  bool _isRecording = false;
  Timer? _recordingTimer;
  int _recordingDuration = 0;

  final StreamController<int> _recordingDurationController = StreamController<int>.broadcast();
  Stream<int> get recordingDurationStream => _recordingDurationController.stream;

  final StreamController<bool> _isRecordingController = StreamController<bool>.broadcast();
  Stream<bool> get isRecordingStream => _isRecordingController.stream;

  AudioService(this._supabase) {
    _player.onPlayerStateChanged.listen((state) {});
  }

  /// Vérification des permissions (adaptée au Web)
  Future<bool> hasPermission() async {
    if (kIsWeb) {
      try {
        final mediaDevices = html.window.navigator.mediaDevices;
        if (mediaDevices != null) {
          final stream = await mediaDevices.getUserMedia({'audio': true});
          if (stream != null) {
            stream.getTracks().forEach((track) => track.stop());
            return true;
          }
        }
        return false;
      } catch (_) {
        return false;
      }
    }
    return await _recorder.hasPermission();
  }

  /// Démarrage de l'enregistrement (adapté au Web)
  Future<void> startRecording() async {
    if (_isRecording) return;
    try {
      final hasPerm = await hasPermission();
      if (!hasPerm) throw Exception('Permission microphone refusée');

      if (kIsWeb) {
        // Sur Web, pas de chemin local, on passe null
        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.opus,
            sampleRate: 48000,
          ),
          path: null, // ✅ Web : pas de chemin
        );
      } else {
        final directory = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final filePath = path.join(directory.path, 'audio_$timestamp.m4a');
        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: filePath,
        );
        _currentRecordingPath = filePath;
      }

      _isRecording = true;
      _recordingDuration = 0;
      _isRecordingController.add(true);

      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _recordingDuration++;
        _recordingDurationController.add(_recordingDuration);
      });
    } catch (e) {
      debugPrint('❌ Erreur startRecording: $e');
      rethrow;
    }
  }

  /// Arrêt de l'enregistrement
  Future<String?> stopRecording() async {
    if (!_isRecording) return null;
    try {
      _recordingTimer?.cancel();
      _recordingTimer = null;
      _isRecording = false;
      _isRecordingController.add(false);
      _recordingDurationController.add(0);

      final recordPath = await _recorder.stop();
      if (kIsWeb) {
        // recordPath est une URL blob:http://...
        _currentRecordingPath = recordPath;
      } else {
        _currentRecordingPath = recordPath;
      }
      return recordPath;
    } catch (e) {
      debugPrint('❌ Erreur stopRecording: $e');
      return null;
    }
  }

  /// Annulation de l'enregistrement (supprime le fichier local)
  Future<void> cancelRecording() async {
    if (_currentRecordingPath != null && !kIsWeb) {
      try {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('❌ Erreur cancelRecording: $e');
      }
    }
    _recordingTimer?.cancel();
    _recordingTimer = null;
    _isRecording = false;
    _isRecordingController.add(false);
    _recordingDurationController.add(0);
    _currentRecordingPath = null;
  }

  /// Upload du fichier audio vers Supabase (adapté au Web)
  Future<String?> uploadAudio({
    required String filePath,
    required String conversationId,
    String bucket = 'audio',
  }) async {
    try {
      Uint8List bytes;
      if (kIsWeb) {
        // filePath est une URL blob
        final uri = Uri.parse(filePath);
        final response = await http.get(uri);
        bytes = Uint8List.fromList(response.bodyBytes);
      } else {
        final file = File(filePath);
        if (!await file.exists()) throw Exception('Fichier audio introuvable');
        bytes = Uint8List.fromList(await file.readAsBytes());
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$conversationId.${kIsWeb ? 'webm' : 'm4a'}';
      final storagePath = 'messages/$conversationId/$fileName';

      await _supabase.storage.from(bucket).uploadBinary(storagePath, bytes);

      final publicUrl = _supabase.storage.from(bucket).getPublicUrl(storagePath);

      // Nettoyage (sur Web, on ne supprime pas)
      if (!kIsWeb) {
        try {
          final file = File(filePath);
          if (await file.exists()) await file.delete();
        } catch (_) {}
      }

      return publicUrl;
    } catch (e) {
      debugPrint('❌ Erreur uploadAudio: $e');
      return null;
    }
  }

  /// Récupère la durée d'un fichier audio (en secondes)
  Future<int> getAudioDuration(String filePath) async {
    try {
      final player = AudioPlayer();
      if (kIsWeb) {
        await player.setSourceUrl(filePath); // URL blob ou publique
      } else {
        await player.setSourceDeviceFile(filePath);
      }
      final duration = await player.getDuration();
      await player.dispose();
      return duration?.inSeconds ?? 0;
    } catch (e) {
      debugPrint('❌ Erreur getAudioDuration: $e');
      return 0;
    }
  }

  // ----- Lecture audio -----
  Future<void> play(String url) async {
    try {
      await _player.stop();
      await _player.play(UrlSource(url));
    } catch (e) {
      debugPrint('❌ Erreur play: $e');
      rethrow;
    }
  }

  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (e) {
      debugPrint('❌ Erreur pause: $e');
    }
  }

  Future<void> resume() async {
    try {
      await _player.resume();
    } catch (e) {
      debugPrint('❌ Erreur resume: $e');
    }
  }

  Future<void> stopPlayer() async {
    try {
      await _player.stop();
    } catch (e) {
      debugPrint('❌ Erreur stopPlayer: $e');
    }
  }

  Future<void> seek(double progress) async {
    try {
      final duration = await _player.getDuration();
      if (duration != null) {
        final position = Duration(milliseconds: (duration.inMilliseconds * progress).round());
        await _player.seek(position);
      }
    } catch (e) {
      debugPrint('❌ Erreur seek: $e');
    }
  }

  Stream<Duration> get positionStream => _player.onPositionChanged;
  Stream<Duration> get durationStream => _player.onDurationChanged;

  // Libération des ressources
  void dispose() {
    _recordingTimer?.cancel();
    _player.dispose();
    _recorder.dispose();
    _recordingDurationController.close();
    _isRecordingController.close();
  }

  // Getters
  int get currentRecordingDuration => _recordingDuration;
  bool get isRecording => _isRecording;
}
