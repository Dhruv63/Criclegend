import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/signup_screen.dart';
import '../features/onboarding/presentation/profile_setup_screen.dart';
import '../features/home/presentation/main_layout.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/home/presentation/looking_screen.dart';
import '../features/home/presentation/my_cricket_screen.dart';
import '../features/home/presentation/community_screen.dart';
import '../features/home/presentation/store_screen.dart';
import '../features/scoring/presentation/create_match_screen.dart';
import '../features/teams/presentation/my_teams_screen.dart';
import '../features/teams/presentation/team_detail_screen.dart';
import '../features/scoring/presentation/scoring_screen.dart';
import '../features/admin/presentation/admin_login_screen.dart';
import '../features/admin/presentation/admin_match_console.dart';
import '../features/home/presentation/live_match_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorHomeKey = GlobalKey<NavigatorState>(debugLabel: 'shellHome');
final _shellNavigatorLookingKey = GlobalKey<NavigatorState>(debugLabel: 'shellLooking');
final _shellNavigatorMyCricketKey = GlobalKey<NavigatorState>(debugLabel: 'shellMyCricket');
final _shellNavigatorCommunityKey = GlobalKey<NavigatorState>(debugLabel: 'shellCommunity');
final _shellNavigatorStoreKey = GlobalKey<NavigatorState>(debugLabel: 'shellStore');

final goRouterProvider = Provider<GoRouter>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(authRepo.authStateChanges()),
    redirect: (context, state) {
      final session = authRepo.currentUser;
      final isLoggedIn = session != null;
      final isLoggingIn = state.uri.path == '/login' || state.uri.path == '/login/signup';
      final isAdmin = state.uri.path.startsWith('/admin');

      if (isAdmin) return null; // Let Admin Flow handle itself

      if (!isLoggedIn && !isLoggingIn) {
         return '/login';
      }

      if (isLoggedIn && isLoggingIn) {
        return '/home';
      }

      return null;
    },
    routes: [
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminLoginScreen(),
      routes: [
        GoRoute(
          path: 'console',
          builder: (context, state) => const AdminMatchConsole(),
        ),
      ],
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
      routes: [
        GoRoute(
          path: 'signup',
          builder: (context, state) => const SignUpScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/profile-setup',
      builder: (context, state) => const ProfileSetupScreen(),
    ),
    // Stateful Nested Navigation (Bottom Tab Bar)
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainLayout(navigationShell: navigationShell);
      },
      branches: [
        // Tab 1: Home
        StatefulShellBranch(
          navigatorKey: _shellNavigatorHomeKey,
          routes: [
             GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
          ],
        ),
        // Tab 2: Looking
        StatefulShellBranch(
          navigatorKey: _shellNavigatorLookingKey,
          routes: [
             GoRoute(path: '/looking', builder: (context, state) => const LookingScreen()),
          ],
        ),
        // Tab 3: My Cricket
        StatefulShellBranch(
          navigatorKey: _shellNavigatorMyCricketKey,
          routes: [
             GoRoute(path: '/my-cricket', builder: (context, state) => const MyCricketScreen()),
          ],
        ),
        // Tab 4: Community
        StatefulShellBranch(
          navigatorKey: _shellNavigatorCommunityKey,
          routes: [
             GoRoute(path: '/community', builder: (context, state) => const CommunityScreen()),
          ],
        ),
        // Tab 5: Store
        StatefulShellBranch(
          navigatorKey: _shellNavigatorStoreKey,
          routes: [
             GoRoute(path: '/store', builder: (context, state) => const StoreScreen()),
          ],
        ),
      ],
    ),
    
    // OTHER ROUTES (Push on top of tabs)
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey, 
      path: '/new-match',
      builder: (context, state) => const CreateMatchScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/scoring/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return ScoringScreen(matchId: id);
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/live-match/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return LiveMatchScreen(matchId: id);
      },
    ),
    // Team Management Routes
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/my-teams',
      builder: (context, state) => const MyTeamsScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/team/:id',
      builder: (context, state) {
        final team = state.extra as Map<String, dynamic>;
        return TeamDetailScreen(team: team);
      },
    ),
  ],
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<AuthState> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
