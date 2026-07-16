import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nia_flutter/domain/models.dart';
import 'package:nia_flutter/realtime/realtime_client.dart';
import 'package:nia_flutter/realtime/webrtc_transport.dart';

void main() {
  test('WebRTC uses the short-lived grant and sends typed protocol events',
      () async {
    late http.Request request;
    final transport = _FakeWebRtcTransport();
    final client = WebRtcRealtimeClient(
      transport: transport,
      httpClient: MockClient((captured) async {
        request = captured;
        return http.Response('answer-sdp', 200);
      }),
    );
    final events = <RealtimeEvent>[];
    final subscription = client.events.listen(events.add);

    final connection = client.connect(_grant());
    transport.emit(WebRtcTransportEventKind.dataChannelOpen);
    await connection;
    expect(request.body, 'offer-sdp');
    expect(request.headers['authorization'], 'Bearer short-lived-secret');
    expect(transport.answer, 'answer-sdp');

    await client.sendText('I am agree with that.');
    expect(
        events.any((event) => event.kind == RealtimeEventKind.ready), isTrue);
    expect(transport.sent, hasLength(2));
    expect(
      (jsonDecode(transport.sent.first) as Map<String, Object?>)['type'],
      'conversation.item.create',
    );
    expect(
      (jsonDecode(transport.sent.last) as Map<String, Object?>)['type'],
      'response.create',
    );

    transport.emitMessage(
      '{"type":"response.output_text.delta","delta":"Hello "}',
    );
    transport.emitMessage(
      '{"type":"response.output_text.done","text":"Hello there"}',
    );
    transport.emitMessage(
      '{"type":"conversation.item.input_audio_transcription.completed",'
      '"transcript":"My answer"}',
    );
    await Future<void>.delayed(Duration.zero);
    expect(
      events
          .where((event) => event.kind == RealtimeEventKind.assistantDelta)
          .single
          .text,
      'Hello ',
    );
    expect(
      events
          .where((event) => event.kind == RealtimeEventKind.assistantDone)
          .single
          .text,
      'Hello there',
    );
    expect(
      events
          .where((event) => event.kind == RealtimeEventKind.userTranscript)
          .single
          .text,
      'My answer',
    );

    await client.dispose();
    await subscription.cancel();
  });

  test('microphone denial keeps typed chat available', () async {
    final transport = _FakeWebRtcTransport(microphoneAvailable: false);
    final client = WebRtcRealtimeClient(
      transport: transport,
      httpClient: MockClient((_) async => http.Response('answer-sdp', 200)),
    );
    final events = <RealtimeEvent>[];
    final subscription = client.events.listen(events.add);

    final connection = client.connect(_grant());
    transport.emit(WebRtcTransportEventKind.dataChannelOpen);
    await connection;
    await client.sendText('Typed practice still works.');

    expect(
      events.any(
        (event) => event.kind == RealtimeEventKind.microphoneUnavailable,
      ),
      isTrue,
    );
    expect(transport.sent, hasLength(2));
    await expectLater(
      client.setMicrophoneEnabled(true),
      throwsA(isA<RealtimeTransportException>()),
    );

    await client.dispose();
    await subscription.cancel();
  });

  test('unexpected realtime frames do not escape the data callback', () async {
    final transport = _FakeWebRtcTransport();
    final client = WebRtcRealtimeClient(
      transport: transport,
      httpClient: MockClient((_) async => http.Response('answer-sdp', 200)),
    );
    final events = <RealtimeEvent>[];
    final subscription = client.events.listen(events.add);
    final connection = client.connect(_grant());
    transport.emit(WebRtcTransportEventKind.dataChannelOpen);
    await connection;

    transport.emitMessage('not-json');
    transport.emitMessage(
      '{"type":"response.output_text.delta","delta":42}',
    );
    transport.emitMessage('{"type":false}');

    expect(events.where((event) => event.kind == RealtimeEventKind.error),
        isEmpty);
    await client.dispose();
    await subscription.cancel();
  });

  test('connection fails closed when the data channel never becomes ready',
      () async {
    final transport = _FakeWebRtcTransport();
    final client = WebRtcRealtimeClient(
      transport: transport,
      readyTimeout: const Duration(milliseconds: 10),
      httpClient: MockClient((_) async => http.Response('answer-sdp', 200)),
    );

    await expectLater(
      client.connect(_grant()),
      throwsA(
        isA<RealtimeTransportException>().having(
          (error) => error.message,
          'message',
          contains('too long to become ready'),
        ),
      ),
    );
    expect(transport.closed, isTrue);

    await client.dispose();
  });
}

RealtimeGrant _grant() {
  final now = DateTime.now().toUtc();
  return RealtimeGrant(
    conversation: ConversationSummary(
      id: 'conv_test_12345678',
      status: ConversationStatus.active,
      preferences: const TutorPreferences.defaults(),
      createdAt: now,
      turnCount: 0,
    ),
    transport: 'webrtc',
    endpoint: Uri.parse('https://api.openai.com/v1/realtime/calls'),
    model: 'gpt-realtime-2.1',
    clientSecret: 'short-lived-secret',
    expiresAt: now.add(const Duration(minutes: 1)),
  );
}

class _FakeWebRtcTransport implements WebRtcTransport {
  _FakeWebRtcTransport({this.microphoneAvailable = true});

  final _events = StreamController<WebRtcTransportEvent>.broadcast(sync: true);

  @override
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  @override
  final bool microphoneAvailable;

  @override
  bool get rendererInitialized => false;

  final List<String> sent = <String>[];
  String? answer;
  bool closed = false;

  @override
  Stream<WebRtcTransportEvent> get events => _events.stream;

  void emit(WebRtcTransportEventKind kind) {
    _events.add(WebRtcTransportEvent(kind));
  }

  void emitMessage(String message) {
    _events.add(
      WebRtcTransportEvent(
        WebRtcTransportEventKind.message,
        text: message,
      ),
    );
  }

  @override
  Future<String> start() async {
    if (!microphoneAvailable) {
      emit(WebRtcTransportEventKind.microphoneUnavailable);
    }
    return 'offer-sdp';
  }

  @override
  Future<void> applyAnswer(String sdp) async {
    answer = sdp;
  }

  @override
  Future<void> send(String message) async {
    sent.add(message);
  }

  @override
  Future<void> setMicrophoneEnabled(bool enabled) async {
    if (!microphoneAvailable) throw const MicrophoneUnavailableException();
  }

  @override
  Future<void> close() async {
    closed = true;
  }

  @override
  Future<void> dispose() async {
    closed = true;
    await _events.close();
  }
}
