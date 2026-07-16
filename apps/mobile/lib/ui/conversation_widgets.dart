import 'package:flutter/material.dart';
import 'package:nia_flutter/core/theme/nia_theme.dart';
import 'package:nia_flutter/domain/models.dart';

class TranscriptBubble extends StatelessWidget {
  const TranscriptBubble({
    required this.role,
    required this.text,
    super.key,
    this.streaming = false,
    this.compact = false,
  });

  final TurnRole role;
  final String text;
  final bool streaming;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final user = role == TurnRole.user;
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Semantics(
        label: user ? 'You said' : 'Nia said',
        child: Container(
          constraints: BoxConstraints(maxWidth: compact ? 580 : 620),
          margin: EdgeInsets.only(bottom: compact ? 10 : 12),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 17 : 18,
            vertical: compact ? 13 : 14,
          ),
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
                    fontSize: compact ? 14 : 16,
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
