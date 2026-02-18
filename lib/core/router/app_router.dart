import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/meetings/presentation/screens/home_screen.dart';
import '../../features/meetings/presentation/screens/meeting_detail_screen.dart';
import '../../features/recording/presentation/screens/recording_screen.dart';
import '../../features/action_items/presentation/screens/action_items_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isOnLogin = state.matchedLocation == '/login';

      if (session == null && !isOnLogin) return '/login';
      if (session != null && isOnLogin) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomeScreen(),
              routes: [
                GoRoute(
                  path: 'meeting/:id',
                  builder: (context, state) => MeetingDetailScreen(
                    meetingId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/record',
                builder: (context, state) => const RecordingScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/actions',
                builder: (context, state) => const ActionItemsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen()),
          ]),
        ],
      ),
    ],
  );
});

class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 600;

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: navigationShell.goBranch,
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                    icon: Icon(Icons.home), label: Text('Home')),
                NavigationRailDestination(
                    icon: Icon(Icons.mic), label: Text('Gravar')),
                NavigationRailDestination(
                    icon: Icon(Icons.checklist), label: Text('Acoes')),
                NavigationRailDestination(
                    icon: Icon(Icons.settings), label: Text('Config')),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: navigationShell.goBranch,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.mic), label: 'Gravar'),
          NavigationDestination(icon: Icon(Icons.checklist), label: 'Acoes'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Config'),
        ],
      ),
    );
  }
}
