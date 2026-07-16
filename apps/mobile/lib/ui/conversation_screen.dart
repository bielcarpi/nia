import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:nia_flutter/core/theme/nia_theme.dart';
import 'package:nia_flutter/data/repositories.dart';
import 'package:nia_flutter/domain/models.dart';
import 'package:nia_flutter/realtime/realtime_client.dart';
import 'package:nia_flutter/ui/history_screen.dart';
import 'package:nia_flutter/ui/shared.dart';

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({
    required this.grant,
    required this.repository,
    required this.realtimeClient,
    super.key,
  });

  final RealtimeGrant grant;
  final ConversationRepository repository;
  final RealtimeClient realtimeClient;

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final _turns = <ConversationTurn>[];
  final _composer = TextEditingController();
  final _scroll = ScrollController();
  StreamSubscription<RealtimeEvent>? _subscription;
  String _assistantDraft = '';
  String? _error;
  bool _ready = false;
  bool _connecting = true;
  bool _microphoneEnabled = false;
  bool _changingMicrophone = false;
  bool _sending = false;
  bool _awaitingAssistant = false;
  bool _ending = false;
  int _turnCounter = 0;
  Future<void> _pendingWrites = Future<void>.value();
  final Map<String, ConversationTurn> _unsyncedTurns =
      <String, ConversationTurn>{};

  bool get _hasLearnerTurn => _turns.any((turn) => turn.role == TurnRole.user);

  bool get _canComplete =>
      !_ending &&
      !_connecting &&
      _hasLearnerTurn &&
      !_microphoneEnabled &&
      !_awaitingAssistant;

  @override
  void initState() {
    super.initState();
    _subscription = widget.realtimeClient.events.listen(
      _handleRealtimeEvent,
      onError: (Object _) {
        if (mounted) {
          setState(() {
            _error = 'The realtime connection ended unexpectedly.';
            _ready = false;
            _connecting = false;
          });
        }
      },
    );
    unawaited(_connect());
  }

  Future<void> _connect() async {
    try {
      await widget.realtimeClient.connect(widget.grant);
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _connecting = false;
          _ready = false;
          _error = friendlyError(error);
        });
      }
    }
  }

  void _handleRealtimeEvent(RealtimeEvent event) {
    if (!mounted) return;
    switch (event.kind) {
      case RealtimeEventKind.ready:
        setState(() {
          _ready = true;
          _connecting = false;
          _error = null;
        });
      case RealtimeEventKind.userTranscript:
        final text = event.text?.trim();
        if (text?.isNotEmpty == true) _addTurn(TurnRole.user, text!);
      case RealtimeEventKind.assistantDelta:
        final delta = event.text;
        if (delta?.isNotEmpty == true) {
          setState(() {
            _awaitingAssistant = true;
            _assistantDraft += delta!;
          });
          _scrollToEnd();
        }
      case RealtimeEventKind.assistantDone:
        final finalText = event.text?.trim() ?? '';
        final text = finalText.isNotEmpty ? finalText : _assistantDraft.trim();
        setState(() {
          _assistantDraft = '';
          _awaitingAssistant = false;
        });
        if (text.isNotEmpty) _addTurn(TurnRole.assistant, text);
      case RealtimeEventKind.microphoneChanged:
        setState(() {
          _microphoneEnabled = event.microphoneEnabled ?? false;
          _changingMicrophone = false;
        });
      case RealtimeEventKind.error:
        setState(() {
          _awaitingAssistant = false;
          _error = event.text ?? 'The live session reported an error.';
        });
      case RealtimeEventKind.closed:
        if (!_ending) {
          setState(() {
            _ready = false;
            _connecting = false;
            _microphoneEnabled = false;
            _awaitingAssistant = false;
          });
        }
    }
  }

  void _addTurn(TurnRole role, String text) {
    final turn = ConversationTurn(
      id: 'mobile-${DateTime.now().microsecondsSinceEpoch}-${_turnCounter++}',
      role: role,
      text: text,
      occurredAt: DateTime.now().toUtc(),
    );
    setState(() {
      _turns.add(turn);
      if (role == TurnRole.user) _awaitingAssistant = true;
    });
    _scrollToEnd();
    _queuePersist(turn);
  }

  void _queuePersist(ConversationTurn turn) {
    _unsyncedTurns[turn.id] = turn;
    _pendingWrites = _pendingWrites.then((_) async {
      try {
        await widget.repository.saveTurn(widget.grant.conversation.id, turn);
        _unsyncedTurns.remove(turn.id);
      } on Object {
        if (mounted) {
          setState(() {
            _error = 'A transcript turn is waiting to sync. Nia will retry '
                'before generating feedback.';
          });
        }
      }
    });
  }

  Future<void> _flushPendingTurns() async {
    await _pendingWrites;
    if (_unsyncedTurns.isEmpty) return;

    final retry = _unsyncedTurns.values.toList(growable: false);
    try {
      for (final turn in retry) {
        await widget.repository.saveTurn(widget.grant.conversation.id, turn);
        _unsyncedTurns.remove(turn.id);
      }
    } on Object {
      throw const RealtimeTransportException(
        'The transcript is not fully synced, so feedback was not generated '
        'from partial data. Check your connection and tap Finish again.',
      );
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendText() async {
    final text = _composer.text.trim();
    if (text.isEmpty || !_ready || _sending) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    _composer.clear();
    _addTurn(TurnRole.user, text);
    try {
      await widget.realtimeClient.sendText(text);
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _awaitingAssistant = false;
          _error = friendlyError(error);
        });
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _toggleMicrophone() async {
    if (!_ready || _changingMicrophone) return;
    setState(() {
      _changingMicrophone = true;
      _error = null;
    });
    try {
      await widget.realtimeClient.setMicrophoneEnabled(!_microphoneEnabled);
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _changingMicrophone = false;
          _error = friendlyError(error);
        });
      }
    }
  }

  Future<void> _complete() async {
    if (!_canComplete) return;
    setState(() {
      _ending = true;
      _error = null;
    });
    try {
      await widget.realtimeClient.close();
      await _flushPendingTurns();
      final detail = await widget.repository.complete(
        widget.grant.conversation.id,
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute<void>(
          builder: (_) => ConversationDetailScreen(
            conversationId: widget.grant.conversation.id,
            repository: widget.repository,
            initialDetail: detail,
          ),
        ),
      );
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _ending = false;
          _ready = false;
          _error = friendlyError(error);
        });
      }
    }
  }

  Future<void> _requestLeave() async {
    if (_ending) return;
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave this session?'),
        content: const Text(
          'The microphone will stop immediately. Finish the session first if you want feedback.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep practising'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (leave != true || !mounted) return;
    setState(() => _ending = true);
    await widget.realtimeClient.close();
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _composer.dispose();
    _scroll.dispose();
    unawaited(_subscription?.cancel());
    unawaited(widget.realtimeClient.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope<void>(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) unawaited(_requestLeave());
        },
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              tooltip: 'Leave session',
              onPressed: _requestLeave,
              icon: const Icon(Icons.close),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  widget.grant.conversation.preferences.topic,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${widget.grant.conversation.preferences.targetLanguage.label} · '
                  '${widget.grant.conversation.preferences.level.label}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            actions: <Widget>[
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: FilledButton.tonal(
                  onPressed: _canComplete ? _complete : null,
                  child: Text(
                    _ending
                        ? 'Finishing…'
                        : _awaitingAssistant
                            ? 'Nia is replying…'
                            : 'Finish',
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            top: false,
            child: Column(
              children: <Widget>[
                if (widget.realtimeClient case final RealtimeAudioSink sink
                    when sink.audioSinkReady)
                  ExcludeSemantics(
                    child: SizedBox.square(
                      dimension: 1,
                      child: RTCVideoView(sink.remoteRenderer),
                    ),
                  ),
                _SessionStatus(
                  connecting: _connecting,
                  ready: _ready,
                  microphoneEnabled: _microphoneEnabled,
                  demo: widget.grant.transport == 'demo',
                ),
                if (_error != null)
                  MaterialBanner(
                    content: Text(_error!),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => setState(() => _error = null),
                        child: const Text('Dismiss'),
                      ),
                    ],
                  ),
                Expanded(
                  child: PageWidth(
                    maxWidth: 860,
                    child: _turns.isEmpty && _assistantDraft.isEmpty
                        ? _ConversationEmpty(connecting: _connecting)
                        : ListView.builder(
                            controller: _scroll,
                            padding: const EdgeInsets.fromLTRB(18, 24, 18, 16),
                            itemCount: _turns.length +
                                (_assistantDraft.isEmpty ? 0 : 1),
                            itemBuilder: (context, index) {
                              if (index == _turns.length) {
                                return _MessageBubble(
                                  role: TurnRole.assistant,
                                  text: _assistantDraft,
                                  streaming: true,
                                );
                              }
                              final turn = _turns[index];
                              return _MessageBubble(
                                role: turn.role,
                                text: turn.text,
                              );
                            },
                          ),
                  ),
                ),
                _Composer(
                  controller: _composer,
                  enabled: _ready && !_ending && !_awaitingAssistant,
                  sending: _sending,
                  microphoneEnabled: _microphoneEnabled,
                  changingMicrophone: _changingMicrophone,
                  onMic: _toggleMicrophone,
                  onSend: _sendText,
                ),
              ],
            ),
          ),
        ),
      );
}

class _SessionStatus extends StatelessWidget {
  const _SessionStatus({
    required this.connecting,
    required this.ready,
    required this.microphoneEnabled,
    required this.demo,
  });

  final bool connecting;
  final bool ready;
  final bool microphoneEnabled;
  final bool demo;

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = connecting
        ? (Icons.sync, 'Securing session…', NiaColors.peach)
        : microphoneEnabled
            ? (Icons.mic, 'Listening now', NiaColors.peach)
            : ready
                ? (
                    Icons.check_circle,
                    demo ? 'Demo ready' : 'Private connection ready',
                    NiaColors.mint,
                  )
                : (Icons.cloud_off, 'Disconnected', const Color(0xFFFFD4D4));
    return Container(
      width: double.infinity,
      color: color,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, size: 17),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '$label${demo ? ' · Mic triggers one scripted turn' : ''}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationEmpty extends StatelessWidget {
  const _ConversationEmpty({required this.connecting});
  final bool connecting;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(22),
                decoration: const BoxDecoration(
                  color: NiaColors.mint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.graphic_eq, size: 38),
              ),
              const SizedBox(height: 18),
              Text(
                connecting
                    ? 'Nia is getting ready…'
                    : 'Say or type something to begin.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
        ),
      );
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.role,
    required this.text,
    this.streaming = false,
  });

  final TurnRole role;
  final String text;
  final bool streaming;

  @override
  Widget build(BuildContext context) {
    final user = role == TurnRole.user;
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Semantics(
        label: user ? 'You said' : 'Nia said',
        child: Container(
          constraints: const BoxConstraints(maxWidth: 620),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: user ? NiaColors.evergreen : NiaColors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(user ? 20 : 5),
              bottomRight: Radius.circular(user ? 5 : 20),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Flexible(
                child: Text(
                  text,
                  style: TextStyle(
                    color: user ? NiaColors.white : NiaColors.ink,
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
              ),
              if (streaming) ...<Widget>[
                const SizedBox(width: 8),
                const SizedBox.square(
                  dimension: 10,
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.enabled,
    required this.sending,
    required this.microphoneEnabled,
    required this.changingMicrophone,
    required this.onMic,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool sending;
  final bool microphoneEnabled;
  final bool changingMicrophone;
  final VoidCallback onMic;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: NiaColors.white,
          border: Border(top: BorderSide(color: Color(0x14152A25))),
        ),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: PageWidth(
          maxWidth: 860,
          child: Row(
            children: <Widget>[
              IconButton.filled(
                tooltip:
                    microphoneEnabled ? 'Mute microphone' : 'Use microphone',
                style: IconButton.styleFrom(
                  backgroundColor:
                      microphoneEnabled ? Colors.red.shade600 : NiaColors.mint,
                  foregroundColor:
                      microphoneEnabled ? Colors.white : NiaColors.evergreen,
                ),
                onPressed: enabled && !changingMicrophone ? onMic : null,
                icon: changingMicrophone
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(microphoneEnabled ? Icons.mic : Icons.mic_none),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  decoration: const InputDecoration(
                    hintText: 'Type what you want to say…',
                    isDense: true,
                  ),
                  onSubmitted: (_) => onSend(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: 'Send message',
                onPressed: enabled && !sending ? onSend : null,
                icon: sending
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.arrow_upward),
              ),
            ],
          ),
        ),
      );
}
