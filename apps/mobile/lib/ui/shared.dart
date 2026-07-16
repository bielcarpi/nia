import 'package:flutter/material.dart';
import 'package:nia_flutter/core/theme/nia_theme.dart';

class NiaWordmark extends StatelessWidget {
  const NiaWordmark({super.key, this.onDark = false});
  final bool onDark;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          NiaMark(onDark: onDark),
          const SizedBox(width: 10),
          Text(
            'nia',
            style: TextStyle(
              color: onDark ? NiaColors.white : NiaColors.ink,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
        ],
      );
}

class NiaMark extends StatelessWidget {
  const NiaMark({super.key, this.onDark = false});
  final bool onDark;

  @override
  Widget build(BuildContext context) => Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: NiaColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: onDark ? const Color(0x33FFFFFF) : const Color(0x14152A25),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(
          'assets/images/logo/nia-mark.png',
          fit: BoxFit.cover,
        ),
      );
}

class PageWidth extends StatelessWidget {
  const PageWidth({required this.child, super.key, this.maxWidth = 1120});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      );
}

class EnvironmentBadge extends StatelessWidget {
  const EnvironmentBadge({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: NiaColors.peach,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.science_outlined, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                letterSpacing: 1,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
}

class ErrorPanel extends StatelessWidget {
  const ErrorPanel({required this.message, required this.onRetry, super.key});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.cloud_off_outlined, size: 36),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
}

String friendlyError(Object error) {
  final text = error.toString().trim();
  return text.isEmpty ? 'Something went wrong. Please retry.' : text;
}

String shortDate(DateTime date) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final local = date.toLocal();
  return '${months[local.month - 1]} ${local.day}, ${local.year}';
}
