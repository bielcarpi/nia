import 'package:flutter/material.dart';
import 'package:nia_flutter/app/dependencies.dart';
import 'package:nia_flutter/core/auth/auth_service.dart';
import 'package:nia_flutter/core/theme/nia_theme.dart';
import 'package:nia_flutter/domain/models.dart';
import 'package:nia_flutter/ui/conversation_screen.dart';
import 'package:nia_flutter/ui/shared.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({
    required this.dependencies,
    required this.user,
    required this.onConversationChanged,
    super.key,
  });

  final AppDependencies dependencies;
  final AuthUser user;
  final VoidCallback onConversationChanged;

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  late Future<TutorPreferences> _loadFuture;
  final _topicController = TextEditingController();
  TutorPreferences? _draft;
  bool _starting = false;
  String? _error;

  static const _topics = <String>[
    'Everyday life',
    'Travel',
    'Work',
    'Food & culture',
  ];

  @override
  void initState() {
    super.initState();
    _loadFuture = widget.dependencies.preferences.load();
  }

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  void _applyLoaded(TutorPreferences preferences) {
    if (_draft != null) return;
    _draft = preferences;
    _topicController.text = preferences.topic;
  }

  Future<void> _startSession() async {
    final draft = _draft;
    if (draft == null || _starting) return;
    final topic = _topicController.text.trim();
    if (topic.length < 2) {
      setState(() => _error = 'Choose a topic before starting.');
      return;
    }
    final preferences = draft.copyWith(topic: topic);
    setState(() {
      _starting = true;
      _error = null;
    });
    try {
      await widget.dependencies.preferences.save(preferences);
      final grant = await widget.dependencies.conversations.createSession(
        preferences,
      );
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => ConversationScreen(
            grant: grant,
            repository: widget.dependencies.conversations,
            realtimeClient: widget.dependencies.realtimeClientFactory(grant),
          ),
        ),
      );
      widget.onConversationChanged();
    } on Object catch (error) {
      if (mounted) setState(() => _error = friendlyError(error));
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: PageWidth(
          child: FutureBuilder<TutorPreferences>(
            future: _loadFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: ErrorPanel(
                      message: friendlyError(
                        snapshot.error ?? 'Preferences unavailable.',
                      ),
                      onRetry: () => setState(() {
                        _loadFuture = widget.dependencies.preferences.load();
                      }),
                    ),
                  ),
                );
              }
              _applyLoaded(snapshot.requireData);
              return _content(context);
            },
          ),
        ),
      );

  Widget _content(BuildContext context) {
    final draft = _draft!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 44),
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const NiaWordmark(),
            if (!widget.dependencies.config.production)
              EnvironmentBadge(
                label: widget.dependencies.config.localStack ? 'LOCAL' : 'DEMO',
              ),
          ],
        ),
        const SizedBox(height: 38),
        Text(
          'Ready when you are,\n${widget.user.displayName.split(' ').first}.',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 10),
        const Text('Tune the session, then practise without pressure.'),
        const SizedBox(height: 26),
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: NiaColors.evergreen,
            borderRadius: BorderRadius.circular(28),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 620;
              final intro = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(Icons.graphic_eq, color: NiaColors.mint, size: 34),
                  const SizedBox(height: 22),
                  Text(
                    '${draft.targetLanguage.greeting}! Let’s get you talking.',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(color: NiaColors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.dependencies.config.offlineDemo
                        ? 'This offline preview responds to what you type and '
                            'keeps everything on this device.'
                        : 'Choose a situation you genuinely want to rehearse.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: NiaColors.mint),
                  ),
                ],
              );
              final button = FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: NiaColors.mint,
                  foregroundColor: NiaColors.evergreen,
                ),
                onPressed: _starting ? null : _startSession,
                icon: _starting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.mic),
                label: Text(_starting ? 'Preparing…' : 'Start conversation'),
              );
              if (wide) {
                return Row(
                  children: <Widget>[
                    Expanded(child: intro),
                    const SizedBox(width: 32),
                    button,
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[intro, const SizedBox(height: 24), button],
              );
            },
          ),
        ),
        const SizedBox(height: 22),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Session setup',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                const _FieldLabel('I want to practise'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: TargetLanguage.values
                      .map(
                        (language) => ChoiceChip(
                          label: Text(language.label),
                          selected: draft.targetLanguage == language,
                          onSelected: (_) => setState(
                            () => _draft = draft.copyWith(
                              targetLanguage: language,
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: 24),
                const _FieldLabel('At this level'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ProficiencyLevel.values
                      .map(
                        (level) => ChoiceChip(
                          label: Text(level.label),
                          selected: draft.level == level,
                          onSelected: (_) => setState(
                            () => _draft = draft.copyWith(level: level),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: 24),
                const _FieldLabel('About'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _topics
                      .map(
                        (topic) => ActionChip(
                          label: Text(topic),
                          onPressed: () => setState(() {
                            _topicController.text = topic;
                            _draft = draft.copyWith(topic: topic);
                          }),
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _topicController,
                  maxLength: 80,
                  decoration: const InputDecoration(
                    hintText: 'Or type a specific scenario',
                    prefixIcon: Icon(Icons.edit_outlined),
                    counterText: '',
                  ),
                  onChanged: (value) => _draft = draft.copyWith(topic: value),
                ),
                const SizedBox(height: 24),
                const _FieldLabel('How Nia should correct me'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: CorrectionStyle.values
                      .map(
                        (style) => ChoiceChip(
                          label: Text(style.label),
                          selected: draft.correctionStyle == style,
                          onSelected: (_) => setState(
                            () =>
                                _draft = draft.copyWith(correctionStyle: style),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: 8),
                Text(draft.correctionStyle.description),
                if (_error != null) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) =>
      Text(label, style: Theme.of(context).textTheme.titleMedium);
}
