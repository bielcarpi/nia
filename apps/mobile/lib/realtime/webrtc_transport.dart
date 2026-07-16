import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';

enum WebRtcTransportEventKind {
  dataChannelOpen,
  dataChannelClosed,
  message,
  microphoneUnavailable,
  connectionFailed,
}

class WebRtcTransportEvent {
  const WebRtcTransportEvent(this.kind, {this.text});

  final WebRtcTransportEventKind kind;
  final String? text;
}

class MicrophoneUnavailableException implements Exception {
  const MicrophoneUnavailableException();

  @override
  String toString() => 'Microphone access is unavailable. Continue by typing.';
}

abstract interface class WebRtcTransport {
  Stream<WebRtcTransportEvent> get events;
  RTCVideoRenderer get remoteRenderer;
  bool get rendererInitialized;
  bool get microphoneAvailable;

  Future<String> start();
  Future<void> applyAnswer(String sdp);
  Future<void> send(String message);
  Future<void> setMicrophoneEnabled(bool enabled);
  Future<void> close();
  Future<void> dispose();
}

class FlutterWebRtcTransport implements WebRtcTransport {
  final _events = StreamController<WebRtcTransportEvent>.broadcast(sync: true);

  @override
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;
  MediaStream? _localStream;
  bool _rendererInitialized = false;
  bool _microphoneAvailable = true;
  bool _closed = false;
  bool _started = false;

  @override
  Stream<WebRtcTransportEvent> get events => _events.stream;

  @override
  bool get rendererInitialized => _rendererInitialized;

  @override
  bool get microphoneAvailable => _microphoneAvailable;

  @override
  Future<String> start() async {
    if (_started) throw StateError('WebRTC transport already started.');
    _started = true;
    await remoteRenderer.initialize();
    _rendererInitialized = true;

    final peerConnection = await createPeerConnection(<String, dynamic>{
      'iceServers': <Object>[],
    });
    _peerConnection = peerConnection;
    peerConnection.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        remoteRenderer.srcObject = event.streams.first;
      }
    };
    peerConnection.onConnectionState = (state) {
      if (_closed) return;
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        _events.add(
          const WebRtcTransportEvent(
            WebRtcTransportEventKind.connectionFailed,
          ),
        );
      }
    };

    try {
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
        await peerConnection.addTrack(track, stream);
      }
    } on Object {
      for (final track in _localStream?.getTracks() ?? <MediaStreamTrack>[]) {
        await track.stop();
      }
      await _localStream?.dispose();
      _localStream = null;
      _microphoneAvailable = false;
      await peerConnection.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
        init: RTCRtpTransceiverInit(
          direction: TransceiverDirection.RecvOnly,
        ),
      );
      _events.add(
        const WebRtcTransportEvent(
          WebRtcTransportEventKind.microphoneUnavailable,
        ),
      );
    }

    final dataChannel = await peerConnection.createDataChannel(
      'oai-events',
      RTCDataChannelInit()..ordered = true,
    );
    _dataChannel = dataChannel;
    dataChannel.onDataChannelState = (state) {
      if (_closed) return;
      if (state == RTCDataChannelState.RTCDataChannelOpen) {
        _events.add(
          const WebRtcTransportEvent(
            WebRtcTransportEventKind.dataChannelOpen,
          ),
        );
      } else if (state == RTCDataChannelState.RTCDataChannelClosed) {
        _events.add(
          const WebRtcTransportEvent(
            WebRtcTransportEventKind.dataChannelClosed,
          ),
        );
      }
    };
    dataChannel.onMessage = (message) {
      if (!_closed && !message.isBinary) {
        _events.add(
          WebRtcTransportEvent(
            WebRtcTransportEventKind.message,
            text: message.text,
          ),
        );
      }
    };

    final offer = await peerConnection.createOffer(<String, dynamic>{
      'offerToReceiveAudio': true,
    });
    final sdp = offer.sdp;
    if (sdp == null || sdp.isEmpty) {
      throw StateError('The device could not create an audio session.');
    }
    await peerConnection.setLocalDescription(offer);
    return sdp;
  }

  @override
  Future<void> applyAnswer(String sdp) async {
    final peerConnection = _peerConnection;
    if (peerConnection == null) {
      throw StateError('WebRTC transport not started.');
    }
    await peerConnection
        .setRemoteDescription(RTCSessionDescription(sdp, 'answer'));
  }

  @override
  Future<void> send(String message) async {
    final dataChannel = _dataChannel;
    if (dataChannel == null ||
        dataChannel.state != RTCDataChannelState.RTCDataChannelOpen) {
      throw StateError('The realtime data channel is not open.');
    }
    await dataChannel.send(RTCDataChannelMessage(message));
  }

  @override
  Future<void> setMicrophoneEnabled(bool enabled) async {
    if (!_microphoneAvailable) throw const MicrophoneUnavailableException();
    for (final track
        in _localStream?.getAudioTracks() ?? <MediaStreamTrack>[]) {
      track.enabled = enabled;
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
  }

  @override
  Future<void> dispose() async {
    await close();
    if (_rendererInitialized) await remoteRenderer.dispose();
    await _events.close();
  }
}
