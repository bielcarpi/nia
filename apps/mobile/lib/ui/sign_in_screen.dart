import 'package:flutter/material.dart';
import 'package:nia_flutter/app/dependencies.dart';
import 'package:nia_flutter/core/theme/nia_theme.dart';
import 'package:nia_flutter/ui/shared.dart';

enum _AuthMode { signIn, createAccount }

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
  _AuthMode _mode = _AuthMode.signIn;
  String? _error;
  String? _notice;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      if (_mode == _AuthMode.signIn) {
        await widget.dependencies.auth.signIn(
          email: _email.text.trim(),
          password: _password.text,
        );
      } else {
        await widget.dependencies.auth.createAccount(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
    } on Object {
      if (mounted) {
        setState(() {
          _error = _mode == _AuthMode.signIn
              ? 'Sign-in failed. Check your details or reset your password.'
              : 'Account creation failed. Try another email or password.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      setState(() {
        _error = 'Enter your email address before requesting a reset.';
        _notice = null;
      });
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      await widget.dependencies.auth.sendPasswordReset(email);
      if (mounted) {
        setState(() => _notice = 'Password reset email sent to $email.');
      }
    } on Object {
      if (mounted) {
        setState(() => _error = 'Password reset could not be sent. Try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toggleMode() {
    setState(() {
      _mode = _mode == _AuthMode.signIn
          ? _AuthMode.createAccount
          : _AuthMode.signIn;
      _error = null;
      _notice = null;
    });
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
                localStack: widget.dependencies.config.localStack,
                mode: _mode,
                formKey: _formKey,
                email: _email,
                password: _password,
                busy: _busy,
                error: _error,
                notice: _notice,
                obscurePassword: _obscurePassword,
                onTogglePassword: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                onSubmit: _submit,
                onResetPassword: _resetPassword,
                onToggleMode: _toggleMode,
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
                    icon: Icons.delete_outline, label: 'History you control'),
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
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Text(
              label,
              style: const TextStyle(
                color: NiaColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
}

class _SignInCard extends StatelessWidget {
  const _SignInCard({
    required this.demoMode,
    required this.localStack,
    required this.mode,
    required this.formKey,
    required this.email,
    required this.password,
    required this.busy,
    required this.error,
    required this.notice,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.onSubmit,
    required this.onResetPassword,
    required this.onToggleMode,
    required this.onDemo,
  });

  final bool demoMode;
  final bool localStack;
  final _AuthMode mode;
  final GlobalKey<FormState> formKey;
  final TextEditingController email;
  final TextEditingController password;
  final bool busy;
  final String? error;
  final String? notice;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;
  final VoidCallback onResetPassword;
  final VoidCallback onToggleMode;
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
          EnvironmentBadge(label: localStack ? 'LOCAL' : 'DEMO'),
          const SizedBox(height: 22),
          Text(
            localStack ? 'Use the local Go stack' : 'Explore the full flow',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 12),
          Text(
            localStack
                ? 'Exercise the real API contract with local demo authentication. '
                    'No Firebase project or provider key is required.'
                : 'Try a transcript-aware scripted conversation, history, and '
                    'feedback. No account, microphone, API key, or network is required.',
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
            label: Text(localStack ? 'Enter local stack' : 'Open the demo'),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              const Icon(Icons.info_outline, size: 17),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  localStack
                      ? 'Conversation data is served by the local API.'
                      : 'Demo data stays in memory and resets on restart.',
                ),
              ),
            ],
          ),
        ],
      );

  Widget _production(BuildContext context) => AutofillGroup(
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                  mode == _AuthMode.signIn
                      ? 'Welcome back'
                      : 'Create your account',
                  style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 10),
              Text(
                mode == _AuthMode.signIn
                    ? 'Sign in to continue your language practice.'
                    : 'Save your preferences, transcripts, and feedback securely.',
              ),
              const SizedBox(height: 26),
              TextFormField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const <String>[AutofillHints.email],
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) => value?.contains('@') == true
                    ? null
                    : 'Enter a valid email address.',
                onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: password,
                obscureText: obscurePassword,
                autocorrect: false,
                enableSuggestions: false,
                autofillHints: <String>[
                  mode == _AuthMode.signIn
                      ? AutofillHints.password
                      : AutofillHints.newPassword,
                ],
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    tooltip:
                        obscurePassword ? 'Show password' : 'Hide password',
                    onPressed: onTogglePassword,
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value?.isNotEmpty != true) return 'Enter your password.';
                  if (mode == _AuthMode.createAccount &&
                      (value?.length ?? 0) < 8) {
                    return 'Use at least 8 characters for a new account.';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => onSubmit(),
              ),
              if (error != null) ...<Widget>[
                const SizedBox(height: 14),
                Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              if (notice != null) ...<Widget>[
                const SizedBox(height: 14),
                Text(
                  notice!,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
              ],
              const SizedBox(height: 22),
              FilledButton(
                onPressed: busy ? null : onSubmit,
                child: busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        mode == _AuthMode.signIn ? 'Sign in' : 'Create account',
                      ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                alignment: WrapAlignment.center,
                children: <Widget>[
                  if (mode == _AuthMode.signIn)
                    TextButton(
                      onPressed: busy ? null : onResetPassword,
                      child: const Text('Forgot password?'),
                    ),
                  TextButton(
                    onPressed: busy ? null : onToggleMode,
                    child: Text(
                      mode == _AuthMode.signIn
                          ? 'Create an account'
                          : 'I already have an account',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}
