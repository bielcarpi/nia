import 'package:flutter/material.dart';
import 'package:nia_flutter/app/dependencies.dart';
import 'package:nia_flutter/core/auth/auth_service.dart';
import 'package:nia_flutter/core/theme/nia_theme.dart';
import 'package:nia_flutter/ui/history_screen.dart';
import 'package:nia_flutter/ui/practice_screen.dart';
import 'package:nia_flutter/ui/shared.dart';

class AppShell extends StatefulWidget {
  const AppShell({required this.dependencies, required this.user, super.key});

  final AppDependencies dependencies;
  final AuthUser user;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  int _historyRevision = 0;

  @override
  Widget build(BuildContext context) {
    final destinations = <NavigationDestination>[
      const NavigationDestination(
        icon: Icon(Icons.forum_outlined),
        selectedIcon: Icon(Icons.forum),
        label: 'Practice',
      ),
      const NavigationDestination(
        icon: Icon(Icons.history_outlined),
        selectedIcon: Icon(Icons.history),
        label: 'History',
      ),
      const NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: 'You',
      ),
    ];
    final pages = <Widget>[
      PracticeScreen(
        dependencies: widget.dependencies,
        user: widget.user,
        onConversationChanged: () => setState(() => _historyRevision++),
      ),
      HistoryScreen(
        key: ValueKey<int>(_historyRevision),
        repository: widget.dependencies.conversations,
      ),
      _ProfileScreen(dependencies: widget.dependencies, user: widget.user),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        if (wide) {
          return Scaffold(
            body: Row(
              children: <Widget>[
                Container(
                  color: NiaColors.white,
                  child: SafeArea(
                    child: NavigationRail(
                      minWidth: 92,
                      labelType: NavigationRailLabelType.all,
                      leading: const Padding(
                        padding: EdgeInsets.only(top: 12, bottom: 32),
                        child: NiaMark(),
                      ),
                      selectedIndex: _selectedIndex,
                      onDestinationSelected: (index) =>
                          setState(() => _selectedIndex = index),
                      destinations: destinations
                          .map(
                            (item) => NavigationRailDestination(
                              icon: item.icon,
                              selectedIcon: item.selectedIcon,
                              label: Text(item.label),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                ),
                Expanded(child: pages[_selectedIndex]),
              ],
            ),
          );
        }
        return Scaffold(
          body: pages[_selectedIndex],
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) =>
                setState(() => _selectedIndex = index),
            destinations: destinations,
          ),
        );
      },
    );
  }
}

class _ProfileScreen extends StatelessWidget {
  const _ProfileScreen({required this.dependencies, required this.user});
  final AppDependencies dependencies;
  final AuthUser user;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: PageWidth(
          maxWidth: 760,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
            children: <Widget>[
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[NiaWordmark()],
              ),
              const SizedBox(height: 42),
              CircleAvatar(
                radius: 34,
                backgroundColor: NiaColors.mint,
                child: Text(
                  user.displayName.isEmpty
                      ? 'N'
                      : user.displayName.substring(0, 1).toUpperCase(),
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                user.displayName,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 4),
              Text(user.email),
              const SizedBox(height: 30),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            'Environment',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (dependencies.config.demoMode) const DemoBadge(),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _InfoLine(
                        icon: Icons.storage_outlined,
                        title: dependencies.config.demoMode
                            ? 'In-memory data'
                            : 'Account-backed history',
                        subtitle: dependencies.config.demoMode
                            ? 'Everything resets when the app restarts.'
                            : 'Conversations are handled by the Nia API.',
                      ),
                      const SizedBox(height: 16),
                      const _InfoLine(
                        icon: Icons.mic_none,
                        title: 'Bounded microphone access',
                        subtitle:
                            'Audio streams only during a live session and tracks stop on exit.',
                      ),
                      const SizedBox(height: 16),
                      const _InfoLine(
                        icon: Icons.password_outlined,
                        title: 'No provider keys in the app',
                        subtitle:
                            'Production receives a short-lived session secret from the Go API.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: dependencies.auth.signOut,
                icon: const Icon(Icons.logout),
                label: Text(
                  dependencies.config.demoMode ? 'Exit demo' : 'Sign out',
                ),
              ),
            ],
          ),
        ),
      );
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: NiaColors.fern),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      );
}
