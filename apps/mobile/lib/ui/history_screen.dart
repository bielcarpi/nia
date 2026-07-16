import 'package:flutter/material.dart';
import 'package:nia_flutter/core/theme/nia_theme.dart';
import 'package:nia_flutter/data/repositories.dart';
import 'package:nia_flutter/domain/models.dart';
import 'package:nia_flutter/ui/shared.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({required this.repository, super.key});
  final ConversationRepository repository;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<ConversationPage> _future;
  String? _deletingId;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.list();
  }

  void _reload() {
    setState(() {
      _future = widget.repository.list();
    });
  }

  Future<void> _delete(ConversationSummary conversation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this conversation?'),
        content: const Text(
          'Its transcript and feedback will be permanently removed.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep it'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _deletingId = conversation.id);
    try {
      await widget.repository.delete(conversation.id);
      _reload();
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(friendlyError(error))));
      }
    } finally {
      if (mounted) setState(() => _deletingId = null);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: PageWidth(
          maxWidth: 880,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const NiaWordmark(),
                    IconButton(
                      tooltip: 'Refresh history',
                      onPressed: _reload,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: 38),
                Text(
                  'Your practice',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Revisit what you said, what worked, and what to try next.',
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: FutureBuilder<ConversationPage>(
                    future: _future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError || !snapshot.hasData) {
                        return Center(
                          child: ErrorPanel(
                            message: friendlyError(
                              snapshot.error ?? 'History unavailable.',
                            ),
                            onRetry: _reload,
                          ),
                        );
                      }
                      final items = snapshot.requireData.items;
                      if (items.isEmpty) return const _EmptyHistory();
                      return ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return _ConversationCard(
                            conversation: item,
                            deleting: _deletingId == item.id,
                            onDelete: () => _delete(item),
                            onOpen: () async {
                              await Navigator.of(context).push<void>(
                                MaterialPageRoute<void>(
                                  builder: (_) => ConversationDetailScreen(
                                    conversationId: item.id,
                                    repository: widget.repository,
                                  ),
                                ),
                              );
                              _reload();
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: NiaColors.mint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.forum_outlined, size: 34),
              ),
              const SizedBox(height: 18),
              Text(
                'No sessions yet',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Your completed conversations and feedback will show up here.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}

class _ConversationCard extends StatelessWidget {
  const _ConversationCard({
    required this.conversation,
    required this.deleting,
    required this.onDelete,
    required this.onOpen,
  });

  final ConversationSummary conversation;
  final bool deleting;
  final VoidCallback onDelete;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: <Widget>[
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: conversation.status == ConversationStatus.completed
                        ? NiaColors.mint
                        : NiaColors.peach,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    conversation.status == ConversationStatus.completed
                        ? Icons.check
                        : Icons.graphic_eq,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        conversation.preferences.topic,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${conversation.preferences.targetLanguage.label} · '
                        '${conversation.preferences.level.label} · '
                        '${shortDate(conversation.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (deleting)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  PopupMenuButton<String>(
                    tooltip: 'Conversation actions',
                    onSelected: (_) => onDelete(),
                    itemBuilder: (_) => const <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: <Widget>[
                            Icon(Icons.delete_outline),
                            SizedBox(width: 10),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      );
}

class ConversationDetailScreen extends StatefulWidget {
  const ConversationDetailScreen({
    required this.conversationId,
    required this.repository,
    super.key,
    this.initialDetail,
  });

  final String conversationId;
  final ConversationRepository repository;
  final ConversationDetail? initialDetail;

  @override
  State<ConversationDetailScreen> createState() =>
      _ConversationDetailScreenState();
}

class _ConversationDetailScreenState extends State<ConversationDetailScreen> {
  late Future<ConversationDetail> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.initialDetail == null
        ? widget.repository.get(widget.conversationId)
        : Future<ConversationDetail>.value(widget.initialDetail);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Session recap')),
        body: SafeArea(
          top: false,
          child: PageWidth(
            maxWidth: 820,
            child: FutureBuilder<ConversationDetail>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: ErrorPanel(
                        message: friendlyError(
                          snapshot.error ?? 'Session unavailable.',
                        ),
                        onRetry: () => setState(() {
                          _future = widget.repository.get(
                            widget.conversationId,
                          );
                        }),
                      ),
                    ),
                  );
                }
                return _DetailContent(detail: snapshot.requireData);
              },
            ),
          ),
        ),
      );
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.detail});
  final ConversationDetail detail;

  @override
  Widget build(BuildContext context) {
    final conversation = detail.conversation;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
      children: <Widget>[
        Text(
          conversation.preferences.topic,
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            Chip(label: Text(conversation.preferences.targetLanguage.label)),
            Chip(label: Text(conversation.preferences.level.label)),
            Chip(label: Text('${conversation.turnCount} turns')),
            Chip(label: Text(shortDate(conversation.createdAt))),
          ],
        ),
        const SizedBox(height: 24),
        if (detail.feedback case final feedback?)
          _FeedbackCard(feedback: feedback)
        else
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Row(
                children: <Widget>[
                  Icon(Icons.hourglass_empty),
                  SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Feedback will appear after this session is completed.',
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 24),
        Text('Transcript', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        if (detail.turns.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No transcript turns were saved.'),
            ),
          )
        else
          ...detail.turns.map((turn) => _TranscriptTurn(turn: turn)),
      ],
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.feedback});
  final SessionFeedback feedback;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: const BoxDecoration(
                      color: NiaColors.mint,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your feedback',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(feedback.summary,
                  style: Theme.of(context).textTheme.bodyLarge),
              if (feedback.strengths.isNotEmpty) ...<Widget>[
                const SizedBox(height: 22),
                const Text(
                  'What worked',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                ...feedback.strengths.map(
                  (item) => _Bullet(icon: Icons.check_circle, text: item),
                ),
              ],
              if (feedback.corrections.isNotEmpty) ...<Widget>[
                const SizedBox(height: 22),
                const Text(
                  'Corrections',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                ...feedback.corrections.map(
                  (item) => Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: NiaColors.cream,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          item.original,
                          style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          item.corrected,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        if (item.explanation.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 5),
                          Text(
                            item.explanation,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
              if (feedback.nextSteps.isNotEmpty) ...<Widget>[
                const SizedBox(height: 16),
                const Text(
                  'Next steps',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                ...feedback.nextSteps.indexed.map(
                  (entry) => _Bullet(
                    icon: Icons.arrow_forward,
                    text: '${entry.$1 + 1}. ${entry.$2}',
                  ),
                ),
              ],
            ],
          ),
        ),
      );
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, size: 18, color: NiaColors.fern),
            const SizedBox(width: 9),
            Expanded(child: Text(text)),
          ],
        ),
      );
}

class _TranscriptTurn extends StatelessWidget {
  const _TranscriptTurn({required this.turn});
  final ConversationTurn turn;

  @override
  Widget build(BuildContext context) {
    final user = turn.role == TurnRole.user;
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 580),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
        decoration: BoxDecoration(
          color: user ? NiaColors.evergreen : NiaColors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          turn.text,
          style: TextStyle(color: user ? NiaColors.white : NiaColors.ink),
        ),
      ),
    );
  }
}
