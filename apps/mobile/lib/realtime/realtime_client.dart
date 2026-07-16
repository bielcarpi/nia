import 'dart:async';
import 'dart:convert';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;
import 'package:nia_flutter/core/api/api_client.dart';
import 'package:nia_flutter/domain/models.dart';

enum RealtimeEventKind {
  ready,
  userTranscript,
  assistantDelta,
  assistantDone,
  microphoneChanged,
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
    final preferences = grant.conversation.preferences;
    final greeting = switch (preferences.targetLanguage) {
      TargetLanguage.spanish =>
        '¡Hola! Hablemos de ${preferences.topic.toLowerCase()}. ¿Cómo empezarías?',
      TargetLanguage.english =>
        'Hello! Let’s talk about ${preferences.topic.toLowerCase()}. How would you begin?',
      TargetLanguage.catalan =>
        'Hola! Parlem de ${preferences.topic.toLowerCase()}. Com començaries?',
    };
    _events.add(RealtimeEvent(RealtimeEventKind.assistantDone, text: greeting));
  }

  @override
  Future<void> sendText(String text) async {
    if (_grant == null || _closed) {
      throw const RealtimeTransportException('The session is not connected.');
    }
    final reply = _replyFor(_grant!.conversation.preferences);
    for (final chunk in _chunks(reply)) {
      if (_closed) return;
      await Future<void>.delayed(const Duration(milliseconds: 90));
      _events.add(RealtimeEvent(RealtimeEventKind.assistantDelta, text: chunk));
    }
    _events.add(RealtimeEvent(RealtimeEventKind.assistantDone, text: reply));
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

  static String _replyFor(
    TutorPreferences preferences,
  ) =>
      switch (preferences.targetLanguage) {
        TargetLanguage.spanish =>
          'Muy bien. Suena natural. Añade un detalle más: ¿cuándo ocurrió y cómo te sentiste?',
        TargetLanguage.english =>
          'Nice work—that sounds natural. Add one more detail: when did it happen, and how did you feel?',
        TargetLanguage.catalan =>
          'Molt bé. Sona natural. Afegeix-hi un detall: quan va passar i com et vas sentir?',
      };

  static Iterable<String> _chunks(String text) sync* {
    final words = text.split(' ');
    for (var index = 0; index < words.length; index += 3) {
      final end = index + 3 < words.length ? index + 3 : words.length;
      yield '${words.sublist(index, end).join(' ')}${end < words.length ? ' ' : ''}';
    }
  }
}

class WebRtcRealtimeClient implements RealtimeClient, RealtimeAudioSink {
  WebRtcRealtimeClient({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final http.Client _http;
  final _events = StreamController<RealtimeEvent>.broadcast();
  @override
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
  bool _rendererInitialized = false;

  @override
  bool get audioSinkReady => _rendererInitialized;
  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;
  MediaStream? _localStream;
  bool _closed = false;

  @override
  Stream<RealtimeEvent> get events => _events.stream;

  @override
  Future<void> connect(RealtimeGrant grant) async {
    if (!grant.canUseWebRtc) {
      throw const RealtimeTransportException(
        'The server did not issue a WebRTC session.',
      );
    }
    if (grant.expiresAt?.isBefore(
          DateTime.now().toUtc().add(const Duration(seconds: 5)),
        ) ??
        false) {
      throw const RealtimeTransportException(
        'The realtime session expired before it could connect.',
      );
    }

    try {
      await remoteRenderer.initialize();
      _rendererInitialized = true;
      final stream = await navigator.mediaDevices.getUserMedia(
        <String, dynamic>{
          'audio': <String, dynamic>{
            'echoCancellation': true,
            'noiseSuppression': true,
            'autoGainControl': true,
          },
          'video': false,
        },
      );
      _localStream = stream;
      for (final track in stream.getAudioTracks()) {
        track.enabled = false;
      }

      final peerConnection = await createPeerConnection(<String, dynamic>{
        'iceServers': <Object>[],
      });
      _peerConnection = peerConnection;
      peerConnection.onTrack = (event) {
        if (event.streams.isNotEmpty) {
          remoteRenderer.srcObject = event.streams.first;
        }
      };
      for (final track in stream.getAudioTracks()) {
        await peerConnection.addTrack(track, stream);
      }

      final dataChannel = await peerConnection.createDataChannel(
        'oai-events',
        RTCDataChannelInit()..ordered = true,
      );
      _dataChannel = dataChannel;
      dataChannel.onDataChannelState = (state) {
        if (_closed) return;
        if (state == RTCDataChannelState.RTCDataChannelOpen) {
          _events.add(const RealtimeEvent(RealtimeEventKind.ready));
        } else if (state == RTCDataChannelState.RTCDataChannelClosed) {
          _events.add(const RealtimeEvent(RealtimeEventKind.closed));
        }
      };
      dataChannel.onMessage = _handleMessage;

      final offer = await peerConnection.createOffer(<String, dynamic>{
        'offerToReceiveAudio': true,
      });
      final sdp = offer.sdp;
      if (sdp == null || sdp.isEmpty) {
        throw const RealtimeTransportException(
          'The device could not create an audio session.',
        );
      }
      await peerConnection.setLocalDescription(offer);
      final response = await _http
          .post(
            grant.endpoint,
            headers: <String, String>{
              'Authorization': 'Bearer ${grant.clientSecret}',
              'Content-Type': 'application/sdp',
            },
            body: sdp,
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw RealtimeTransportException(
          'The realtime service rejected the session '
          '(${response.statusCode}).',
        );
      }
      await peerConnection.setRemoteDescription(
        RTCSessionDescription(response.body, 'answer'),
      );
    } on RealtimeTransportException {
      await close();
      rethrow;
    } on Object {
      await close();
      throw const RealtimeTransportException(
        'Nia could not establish a secure audio session.',
      );
    }
  }

  @override
  Future<void> sendText(String text) async {
    final channel = _dataChannel;
    if (channel == null ||
        channel.state != RTCDataChannelState.RTCDataChannelOpen) {
      throw const RealtimeTransportException(
        'The realtime session is still connecting.',
      );
    }
    await channel.send(
      RTCDataChannelMessage(
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
      ),
    );
    await channel.send(
      RTCDataChannelMessage(
        jsonEncode(<String, Object>{'type': 'response.create'}),
      ),
    );
  }

  @override
  Future<void> setMicrophoneEnabled(bool enabled) async {
    for (final track
        in _localStream?.getAudioTracks() ?? <MediaStreamTrack>[]) {
      track.enabled = enabled;
    }
    if (!_closed) {
      _events.add(
        RealtimeEvent(
          RealtimeEventKind.microphoneChanged,
          microphoneEnabled: enabled,
        ),
      );
    }
  }

  void _handleMessage(RTCDataChannelMessage message) {
    if (_closed || message.isBinary) return;
    try {
      final json = asJsonMap(jsonDecode(message.text) as Object?);
      final type = json?['type'] as String? ?? '';
      if (type == 'response.output_text.delta' ||
          type == 'response.output_audio_transcript.delta') {
        final delta = json?['delta'] as String?;
        if (delta?.isNotEmpty == true) {
          _events.add(
            RealtimeEvent(RealtimeEventKind.assistantDelta, text: delta),
          );
        }
      } else if (type == 'response.output_text.done' ||
          type == 'response.output_audio_transcript.done') {
        final text = json?['text'] as String? ?? json?['transcript'] as String?;
        _events.add(RealtimeEvent(RealtimeEventKind.assistantDone, text: text));
      } else if (type ==
          'conversation.item.input_audio_transcription.completed') {
        final transcript = json?['transcript'] as String?;
        if (transcript?.trim().isNotEmpty == true) {
          _events.add(
            RealtimeEvent(RealtimeEventKind.userTranscript, text: transcript),
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
      // Ignore non-JSON protocol frames. No session content is logged.
    }
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    for (final track in _localStream?.getTracks() ?? <MediaStreamTrack>[]) {
      await track.stop();
    }
    await _localStream?.dispose();
    if (_rendererInitialized) remoteRenderer.srcObject = null;
    await _dataChannel?.close();
    await _peerConnection?.close();
    _events.add(const RealtimeEvent(RealtimeEventKind.closed));
  }

  @override
  Future<void> dispose() async {
    await close();
    _http.close();
    if (_rendererInitialized) await remoteRenderer.dispose();
    await _events.close();
  }
}
