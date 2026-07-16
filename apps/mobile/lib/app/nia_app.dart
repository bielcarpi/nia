import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nia_flutter/app/dependencies.dart';
import 'package:nia_flutter/core/auth/auth_service.dart';
import 'package:nia_flutter/core/theme/nia_theme.dart';
import 'package:nia_flutter/ui/app_shell.dart';
import 'package:nia_flutter/ui/sign_in_screen.dart';

class NiaApp extends StatefulWidget {
  const NiaApp({required this.dependencies, super.key});
  final AppDependencies dependencies;

  @override
  State<NiaApp> createState() => _NiaAppState();
}

class _NiaAppState extends State<NiaApp> {
  @override
  void dispose() {
    unawaited(widget.dependencies.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Nia · Language practice that talks back',
        debugShowCheckedModeBanner: false,
        theme: buildNiaTheme(),
        home: StreamBuilder<AuthUser?>(
          stream: widget.dependencies.auth.authStateChanges,
          initialData: widget.dependencies.auth.currentUser,
          builder: (context, snapshot) {
            final user = snapshot.data;
            return user == null
                ? SignInScreen(dependencies: widget.dependencies)
                : AppShell(dependencies: widget.dependencies, user: user);
          },
        ),
      );
}

class NiaBootstrapErrorApp extends StatelessWidget {
  const NiaBootstrapErrorApp({required this.error, super.key});

  final Object error;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Nia setup required',
        debugShowCheckedModeBanner: false,
        theme: buildNiaTheme(),
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Icon(Icons.settings_suggest_outlined, size: 38),
                          const SizedBox(height: 18),
                          Text(
                            'Nia needs valid runtime configuration',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'The app stopped before opening a network connection. '
                            'Check the documented --dart-define values and restart.',
                          ),
                          const SizedBox(height: 18),
                          SelectableText(
                            _bootstrapMessage(error),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

String _bootstrapMessage(Object error) {
  if (error is StateError) return error.message.toString();
  return 'Startup failed. Verify Firebase and API configuration.';
}
