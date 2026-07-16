import 'package:flutter/material.dart';
import 'package:nia_flutter/app/dependencies.dart';
import 'package:nia_flutter/core/theme/nia_theme.dart';
import 'package:nia_flutter/ui/shared.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({required this.dependencies, super.key});
  final AppDependencies dependencies;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.dependencies.auth.signIn(
        email: _email.text.trim(),
        password: _password.text,
      );
    } on Object {
      if (mounted) {
        setState(() {
          _error = 'Sign-in failed. Check your details and try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _enterDemo() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.dependencies.auth.signInToDemo();
    } on Object {
      if (mounted) {
        setState(() => _error = 'The demo could not start. Please retry.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 860;
              final hero = _HeroPanel(compact: !wide);
              final form = _SignInCard(
                demoMode: widget.dependencies.config.demoMode,
                formKey: _formKey,
                email: _email,
                password: _password,
                busy: _busy,
                error: _error,
                obscurePassword: _obscurePassword,
                onTogglePassword: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                onSignIn: _signIn,
                onDemo: _enterDemo,
              );
              if (wide) {
                return Row(
                  children: <Widget>[
                    Expanded(flex: 6, child: hero),
                    Expanded(
                      flex: 5,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(48),
                        child: form,
                      ),
                    ),
                  ],
                );
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                child: Column(
                  children: <Widget>[hero, const SizedBox(height: 20), form],
                ),
              );
            },
          ),
        ),
      );
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.compact});
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
        constraints: BoxConstraints(minHeight: compact ? 300 : double.infinity),
        padding: EdgeInsets.all(compact ? 28 : 64),
        decoration: BoxDecoration(
          color: NiaColors.evergreen,
          borderRadius: compact ? BorderRadius.circular(32) : BorderRadius.zero,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const NiaWordmark(onDark: true),
            Padding(
              padding: EdgeInsets.symmetric(vertical: compact ? 36 : 72),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Speak more.\nFreeze less.',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          color: NiaColors.white,
                          fontSize: compact ? 42 : 68,
                        ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'A patient AI tutor for low-pressure, real-world '
                    'language practice.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: NiaColors.mint,
                          fontSize: compact ? 16 : 19,
                        ),
                  ),
                ],
              ),
            ),
            const Wrap(
              spacing: 20,
              runSpacing: 10,
              children: <Widget>[
                _TrustPoint(icon: Icons.mic_none, label: 'Live voice'),
                _TrustPoint(icon: Icons.tune, label: 'Your pace'),
                _TrustPoint(
                    icon: Icons.lock_outline, label: 'Private by design'),
              ],
            ),
          ],
        ),
      );
}

class _TrustPoint extends StatelessWidget {
  const _TrustPoint({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: NiaColors.mint, size: 18),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: NiaColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
}

class _SignInCard extends StatelessWidget {
  const _SignInCard({
    required this.demoMode,
    required this.formKey,
    required this.email,
    required this.password,
    required this.busy,
    required this.error,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.onSignIn,
    required this.onDemo,
  });

  final bool demoMode;
  final GlobalKey<FormState> formKey;
  final TextEditingController email;
  final TextEditingController password;
  final bool busy;
  final String? error;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onSignIn;
  final VoidCallback onDemo;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: demoMode ? _demo(context) : _production(context),
          ),
        ),
      );

  Widget _demo(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const DemoBadge(),
          const SizedBox(height: 22),
          Text(
            'Explore the full flow',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 12),
          const Text(
            'Try a scripted conversation, history, and AI-style feedback. '
            'No account, microphone, API key, or network connection required.',
          ),
          if (error != null) ...<Widget>[
            const SizedBox(height: 16),
            Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 26),
          FilledButton.icon(
            onPressed: busy ? null : onDemo,
            icon: busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.arrow_forward),
            label: const Text('Open the demo'),
          ),
          const SizedBox(height: 14),
          const Row(
            children: <Widget>[
              Icon(Icons.info_outline, size: 17),
              SizedBox(width: 8),
              Expanded(
                child: Text('Demo data stays in memory and resets on restart.'),
              ),
            ],
          ),
        ],
      );

  Widget _production(BuildContext context) => Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('Welcome back',
                style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 10),
            const Text('Sign in to continue your language practice.'),
            const SizedBox(height: 26),
            TextFormField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const <String>[AutofillHints.email],
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (value) => value?.contains('@') == true
                  ? null
                  : 'Enter a valid email address.',
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: password,
              obscureText: obscurePassword,
              autofillHints: const <String>[AutofillHints.password],
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  onPressed: onTogglePassword,
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
              validator: (value) => (value?.length ?? 0) >= 8
                  ? null
                  : 'Password must be at least 8 characters.',
              onFieldSubmitted: (_) => onSignIn(),
            ),
            if (error != null) ...<Widget>[
              const SizedBox(height: 14),
              Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 22),
            FilledButton(
              onPressed: busy ? null : onSignIn,
              child: busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Sign in'),
            ),
          ],
        ),
      );
}
