import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/auth/presentation/providers/user_role_provider.dart'; // Moved here
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/signup_screen.dart';
import '../features/onboarding/presentation/profile_setup_screen.dart';
import '../features/home/presentation/main_layout.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/looking/presentation/looking_screen.dart';
import '../features/looking/presentation/create_looking_screen.dart';
import '../features/home/presentation/my_cricket_screen.dart';
import '../features/home/presentation/community_screen.dart';
import '../features/store/presentation/store_home_screen.dart';
import '../features/scoring/presentation/create_match_screen.dart'; // Contains ScheduleMatchScreen class
import '../features/scoring/presentation/pre_match_setup_screen.dart';
import '../features/scoring/presentation/scoring_screen.dart';
import '../features/teams/presentation/my_teams_screen.dart';
import '../features/teams/presentation/team_detail_screen.dart';
import '../features/admin/presentation/admin_login_screen.dart';
import '../features/admin/presentation/admin_match_console.dart';
import '../features/admin/presentation/admin_console_screen.dart';
import '../features/store/presentation/cart_screen.dart';
import '../features/store/presentation/checkout_screen.dart';
import '../features/store/presentation/my_orders_screen.dart';
import '../features/home/presentation/live_match_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();



final goRouterProvider = Provider<GoRouter>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  final roleAsync = ref.watch(userRoleProvider); // Watch the role
  
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(authRepo.authStateChanges()),
    redirect: (context, state) {
      final session = authRepo.currentUser;
      final isLoggedIn = session != null;
      final isLoggingIn = state.uri.path == '/login' || state.uri.path == '/login/signup';
      final isAdminRoute = state.uri.path.startsWith('/admin');

      if (!isLoggedIn && !isLoggingIn) {
         return '/login';
      }

      if (isLoggedIn && isLoggingIn) {
        return '/home';
      }
      
      // RBAC Check
      if (isAdminRoute && isLoggedIn) {
        // If role is still loading or not admin, kick them out
        // Note: For better UX, we might want a loading screen, but for security, deny by default.
        // We check the value directly if available.
        final role = roleAsync.asData?.value ?? 'user'; // Fixed valueOrNull
        if (role != 'admin') {
          return '/home';
        }
      }

      return null;
    },
    routes: [
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminConsoleScreen(),
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
          routes: [
             GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
          ],
        ),
        // Tab 2: Looking
        StatefulShellBranch(
          routes: [
             GoRoute(path: '/looking', builder: (context, state) => const LookingScreen()),
          ],
        ),
        // Tab 3: My Cricket
        StatefulShellBranch(
          routes: [
             GoRoute(path: '/my-cricket', builder: (context, state) => const MyCricketScreen()),
          ],
        ),
        // Tab 4: Community
        StatefulShellBranch(
          routes: [
             GoRoute(path: '/community', builder: (context, state) => const CommunityScreen()),
          ],
        ),
        // Tab 5: Store
        StatefulShellBranch(
          routes: [
             GoRoute(path: '/store', builder: (context, state) => const StoreHomeScreen()),
          ],
        ),
      ],
    ),
    
    // OTHER ROUTES (Push on top of tabs)
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey, 
      path: '/new-match',
      builder: (context, state) => const ScheduleMatchScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/create-looking',
      builder: (context, state) => const CreateLookingScreen(),
    ),
    // Start Match (Schedule)
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/start-match',
      builder: (context, state) => const ScheduleMatchScreen(),
    ),

    // Pre-Match Setup (Toss)
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/match-setup/:matchId',
      builder: (context, state) {
         final matchId = state.pathParameters['matchId']!;
         return PreMatchSetupScreen(matchId: matchId);
      },
    ),

    // Scoring Screen
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/scoring/:matchId',
      builder: (context, state) {
        final matchId = state.pathParameters['matchId']!;
        return ScoringScreen(matchId: matchId);
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

    // Store Routes
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/store/cart',
      builder: (context, state) => const CartScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/store/checkout',
      builder: (context, state) => const CheckoutScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/store/orders',
      builder: (context, state) => const MyOrdersScreen(),
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
