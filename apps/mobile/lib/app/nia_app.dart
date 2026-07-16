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
