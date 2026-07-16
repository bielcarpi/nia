import 'dart:async';
import 'dart:convert';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;
import 'package:nia_flutter/core/api/api_client.dart';
import 'package:nia_flutter/domain/demo_tutor.dart';
import 'package:nia_flutter/domain/models.dart';
import 'package:nia_flutter/realtime/webrtc_transport.dart';

enum RealtimeEventKind {
  ready,
  userTranscript,
  assistantDelta,
  assistantDone,
  microphoneChanged,
  microphoneUnavailable,
  error,
  closed,
}

class RealtimeEvent {
  const RealtimeEvent(this.kind, {this.text, this.microphoneEnabled});

  final RealtimeEventKind kind;
  final String? text;
  final bool? microphoneEnabled;
}

class RealtimeTransportException implements Exception {
  const RealtimeTransportException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class RealtimeClient {
  Stream<RealtimeEvent> get events;
  Future<void> connect(RealtimeGrant grant);
  Future<void> sendText(String text);
  Future<void> setMicrophoneEnabled(bool enabled);
  Future<void> close();
  Future<void> dispose();
}

abstract interface class RealtimeAudioSink {
  RTCVideoRenderer get remoteRenderer;
  bool get audioSinkReady;
}

typedef RealtimeClientFactory = RealtimeClient Function(RealtimeGrant grant);

class DemoRealtimeClient implements RealtimeClient {
  final _events = StreamController<RealtimeEvent>.broadcast();
  RealtimeGrant? _grant;
  bool _closed = false;
  bool _voiceTurnSent = false;

  @override
  Stream<RealtimeEvent> get events => _events.stream;

  @override
  Future<void> connect(RealtimeGrant grant) async {
    _grant = grant;
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (_closed) return;
    _events.add(const RealtimeEvent(RealtimeEventKind.ready));
    _events.add(
      RealtimeEvent(
        RealtimeEventKind.assistantDone,
        text: DemoTutor.greeting(grant.conversation.preferences),
      ),
    );
  }

  @override
  Future<void> sendText(String text) async {
    final grant = _grant;
    if (grant == null || _closed) {
      throw const RealtimeTransportException('The session is not connected.');
    }
    final reply = DemoTutor.reply(grant.conversation.preferences, text);
    for (final chunk in _chunks(reply)) {
      if (_closed) return;
      await Future<void>.delayed(const Duration(milliseconds: 90));
      _events.add(RealtimeEvent(RealtimeEventKind.assistantDelta, text: chunk));
    }
    if (!_closed) {
      _events.add(RealtimeEvent(RealtimeEventKind.assistantDone, text: reply));
    }
  }

  @override
  Future<void> setMicrophoneEnabled(bool enabled) async {
    if (_closed) return;
    _events.add(
      RealtimeEvent(
        RealtimeEventKind.microphoneChanged,
        microphoneEnabled: enabled,
      ),
    );
    if (enabled && !_voiceTurnSent) {
      _voiceTurnSent = true;
      await Future<void>.delayed(const Duration(milliseconds: 550));
      if (_closed) return;
      final transcript =
          switch (_grant?.conversation.preferences.targetLanguage) {
        TargetLanguage.english => 'I would like to practise a real situation.',
        TargetLanguage.catalan => 'M’agradaria practicar una situació real.',
        _ => 'Me gustaría practicar una situación real.',
      };
      _events.add(
        RealtimeEvent(RealtimeEventKind.userTranscript, text: transcript),
      );
      await sendText(transcript);
      if (!_closed) {
        _events.add(
          const RealtimeEvent(
            RealtimeEventKind.microphoneChanged,
            microphoneEnabled: false,
          ),
        );
      }
    }
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _events.add(const RealtimeEvent(RealtimeEventKind.closed));
  }

  @override
  Future<void> dispose() async {
    await close();
    await _events.close();
  }

  static Iterable<String> _chunks(String text) sync* {
    final words = text.split(' ');
    for (var index = 0; index < words.length; index += 3) {
      final end = index + 3 < words.length ? index + 3 : words.length;
      yield '${words.sublist(index, end).join(' ')}${end < words.length ? ' ' : ''}';
    }
  }
}

class WebRtcRealtimeClient implements RealtimeClient, RealtimeAudioSink {
  WebRtcRealtimeClient({
    http.Client? httpClient,
    WebRtcTransport? transport,
    Duration readyTimeout = const Duration(seconds: 15),
  })  : _http = httpClient ?? http.Client(),
        _transport = transport ?? FlutterWebRtcTransport(),
        _readyTimeout = readyTimeout;

  final http.Client _http;
  final WebRtcTransport _transport;
  final Duration _readyTimeout;
  final _events = StreamController<RealtimeEvent>.broadcast();
  StreamSubscription<WebRtcTransportEvent>? _transportSubscription;
  Completer<String?>? _readySignal;
  bool _closed = false;
  bool _connected = false;

  @override
  Stream<RealtimeEvent> get events => _events.stream;

  @override
  RTCVideoRenderer get remoteRenderer => _transport.remoteRenderer;

  @override
  bool get audioSinkReady => _transport.rendererInitialized;

  @override
  Future<void> connect(RealtimeGrant grant) async {
    if (_closed) {
      throw const RealtimeTransportException(
        'The realtime session has already closed.',
      );
    }
    if (_readySignal != null) {
      throw const RealtimeTransportException(
        'The realtime session has already started.',
      );
    }
    if (!grant.canUseWebRtc) {
      throw const RealtimeTransportException(
        'The server did not issue a valid WebRTC session.',
      );
    }
    if (grant.expiresAt?.isBefore(
          DateTime.now().toUtc().add(const Duration(seconds: 5)),
        ) ??
        true) {
      throw const RealtimeTransportException(
        'The realtime session is missing a valid expiry or has expired.',
      );
    }

    final readySignal = Completer<String?>();
    _readySignal = readySignal;
    _transportSubscription ??= _transport.events.listen(_handleTransportEvent);
    try {
      final offer = await _transport.start();
      final response = await _http
          .post(
            grant.endpoint,
            headers: <String, String>{
              'Authorization': 'Bearer ${grant.clientSecret}',
              'Content-Type': 'application/sdp',
            },
            body: offer,
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw RealtimeTransportException(
          'The realtime service rejected the session '
          '(${response.statusCode}).',
        );
      }
      if (response.body.trim().isEmpty) {
        throw const RealtimeTransportException(
          'The realtime service returned an empty session answer.',
        );
      }
      await _transport.applyAnswer(response.body);
      final failure = await readySignal.future.timeout(_readyTimeout);
      if (failure != null) throw RealtimeTransportException(failure);
    } on RealtimeTransportException {
      await close();
      rethrow;
    } on TimeoutException {
      await close();
      throw const RealtimeTransportException(
        'The realtime session took too long to become ready.',
      );
    } on Object {
      await close();
      throw const RealtimeTransportException(
        'Nia could not establish a secure realtime session.',
      );
    }
  }

  void _handleTransportEvent(WebRtcTransportEvent event) {
    if (_closed) return;
    switch (event.kind) {
      case WebRtcTransportEventKind.dataChannelOpen:
        _connected = true;
        final readySignal = _readySignal;
        if (readySignal != null && !readySignal.isCompleted) {
          readySignal.complete(null);
        }
        _events.add(const RealtimeEvent(RealtimeEventKind.ready));
      case WebRtcTransportEventKind.dataChannelClosed:
        unawaited(_failConnection('The realtime connection closed.'));
      case WebRtcTransportEventKind.message:
        _handleProtocolMessage(event.text ?? '');
      case WebRtcTransportEventKind.microphoneUnavailable:
        _events.add(
          const RealtimeEvent(
            RealtimeEventKind.microphoneUnavailable,
            text:
                'Microphone access is unavailable. You can continue by typing.',
          ),
        );
      case WebRtcTransportEventKind.connectionFailed:
        unawaited(_failConnection('The realtime connection was interrupted.'));
    }
  }

  Future<void> _failConnection(String message) async {
    if (_closed) return;
    final readySignal = _readySignal;
    if (readySignal != null && !readySignal.isCompleted) {
      readySignal.complete(message);
    }
    _events.add(RealtimeEvent(RealtimeEventKind.error, text: message));
    await close();
  }

  @override
  Future<void> sendText(String text) async {
    if (_closed || !_connected) {
      throw const RealtimeTransportException(
        'The realtime session is still connecting.',
      );
    }
    try {
      await _transport.send(
        jsonEncode(<String, Object>{
          'type': 'conversation.item.create',
          'item': <String, Object>{
            'type': 'message',
            'role': 'user',
            'content': <Object>[
              <String, Object>{'type': 'input_text', 'text': text},
            ],
          },
        }),
      );
      await _transport.send(
        jsonEncode(<String, Object>{'type': 'response.create'}),
      );
    } on Object {
      throw const RealtimeTransportException(
        'The message could not be sent. Check the session and retry.',
      );
    }
  }

  @override
  Future<void> setMicrophoneEnabled(bool enabled) async {
    try {
      await _transport.setMicrophoneEnabled(enabled);
      if (!_closed) {
        _events.add(
          RealtimeEvent(
            RealtimeEventKind.microphoneChanged,
            microphoneEnabled: enabled,
          ),
        );
      }
    } on MicrophoneUnavailableException {
      throw const RealtimeTransportException(
        'Microphone access is unavailable. Continue by typing.',
      );
    } on Object {
      throw const RealtimeTransportException(
        'The microphone could not be changed. Continue by typing.',
      );
    }
  }

  void _handleProtocolMessage(String message) {
    try {
      final json = asJsonMap(jsonDecode(message));
      final type = json?['type'];
      if (type is! String) return;
      if (type == 'response.output_text.delta' ||
          type == 'response.output_audio_transcript.delta') {
        final delta = json?['delta'];
        if (delta is String && delta.isNotEmpty) {
          _events.add(
            RealtimeEvent(RealtimeEventKind.assistantDelta, text: delta),
          );
        }
      } else if (type == 'response.output_text.done' ||
          type == 'response.output_audio_transcript.done') {
        final text = json?['text'];
        final transcript = json?['transcript'];
        final completed = text is String
            ? text
            : transcript is String
                ? transcript
                : null;
        _events.add(
          RealtimeEvent(RealtimeEventKind.assistantDone, text: completed),
        );
      } else if (type ==
          'conversation.item.input_audio_transcription.completed') {
        final transcript = json?['transcript'];
        if (transcript is String && transcript.trim().isNotEmpty) {
          _events.add(
            RealtimeEvent(
              RealtimeEventKind.userTranscript,
              text: transcript,
            ),
          );
        }
      } else if (type == 'error') {
        _events.add(
          const RealtimeEvent(
            RealtimeEventKind.error,
            text: 'The realtime session reported an error. Please retry.',
          ),
        );
      }
    } on FormatException {
      return;
    } on Object {
      _events.add(
        const RealtimeEvent(
          RealtimeEventKind.error,
          text: 'Nia received an unexpected realtime event.',
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _connected = false;
    final readySignal = _readySignal;
    if (readySignal != null && !readySignal.isCompleted) {
      readySignal.complete(
        'The realtime session closed before it became ready.',
      );
    }
    await _transport.close();
    if (!_events.isClosed) {
      _events.add(const RealtimeEvent(RealtimeEventKind.closed));
    }
  }

  @override
  Future<void> dispose() async {
    await close();
    await _transportSubscription?.cancel();
    _http.close();
    await _transport.dispose();
    await _events.close();
  }
}
