import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'providers/user_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/auth_screens.dart';
import 'screens/home_feed_screen.dart';
import 'screens/post_screens.dart';
import 'screens/section_screens.dart';
import 'screens/profile_screens.dart';
import 'screens/admin_screen.dart';
import 'utils/app_theme.dart';
import 'firebase_options.dart';

// Background FCM handler (must be top-level)
@pragma('vm:entry-point')
Future<void> _fcmBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_fcmBackgroundHandler);
  runApp(const MySuburbApp());
}

class MySuburbApp extends StatelessWidget {
  const MySuburbApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserProvider(),
      child: Consumer<UserProvider>(
        builder: (context, userProvider, _) {
          final router = _buildRouter(userProvider);
          return MaterialApp.router(
            title: 'My Suburb',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            routerConfig: router,
          );
        },
      ),
    );
  }

  GoRouter _buildRouter(UserProvider userProvider) {
    return GoRouter(
      initialLocation: '/splash',
      redirect: (context, state) {
        final isLoading = userProvider.loading;
        final isLoggedIn = userProvider.isLoggedIn;
        final hasProfile = userProvider.user?.suburb.isNotEmpty ?? false;
        final loc = state.uri.path;

        if (isLoading) return loc == '/splash' ? null : '/splash';

        // Not logged in → send to login (unless already there or signing up)
        if (!isLoggedIn) {
          if (loc == '/login' || loc == '/signup' || loc == '/splash') {
            return null;
          }
          return '/login';
        }

        // Logged in but no suburb → select suburb
        if (isLoggedIn && !hasProfile && loc != '/select-suburb') {
          return '/select-suburb';
        }

        // Logged in with profile → skip auth pages
        if (isLoggedIn && hasProfile) {
          if (loc == '/splash' || loc == '/login' || loc == '/signup' ||
              loc == '/select-suburb') {
            return '/';
          }
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (_, __) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (_, __) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          builder: (_, __) => const SignUpScreen(),
        ),
        GoRoute(
          path: '/select-suburb',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return SelectSuburbScreen(
              uid: extra?['uid'],
              email: extra?['email'],
              displayName: extra?['displayName'],
              photoUrl: extra?['photoUrl'],
            );
          },
        ),
        GoRoute(
          path: '/select-suburb-edit',
          builder: (_, __) => const SelectSuburbScreen(isEditing: true),
        ),
        ShellRoute(
          builder: (context, state, child) => _MainShell(child: child),
          routes: [
            GoRoute(
              path: '/',
              builder: (_, __) => const HomeFeedScreen(),
            ),
            GoRoute(
              path: '/marketplace',
              builder: (_, __) => const MarketplaceScreen(),
            ),
            GoRoute(
              path: '/events',
              builder: (_, __) => const EventsScreen(),
            ),
            GoRoute(
              path: '/lost-found',
              builder: (_, __) => const LostFoundScreen(),
            ),
            GoRoute(
              path: '/profile',
              builder: (_, __) => const ProfileScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/create-post',
          builder: (_, __) => const CreatePostScreen(),
        ),
        GoRoute(
          path: '/post/:id',
          builder: (_, state) => PostDetailScreen(postId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/notifications',
          builder: (_, __) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (_, __) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/profile/:uid',
          builder: (_, state) => ProfileScreen(userId: state.pathParameters['uid']),
        ),
        GoRoute(
          path: '/admin',
          builder: (_, __) => const AdminDashboardScreen(),
          redirect: (context, state) {
            final user = userProvider.user;
            if (user == null || !user.isAdmin) return '/';
            return null;
          },
        ),
      ],
    );
  }
}

// ─────────────────────── BOTTOM NAV SHELL ────────────────────────────────────

class _MainShell extends StatelessWidget {
  final Widget child;

  const _MainShell({required this.child});

  static const _tabs = [
    _TabItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home', path: '/'),
    _TabItem(icon: Icons.storefront_outlined, activeIcon: Icons.storefront, label: 'Market', path: '/marketplace'),
    _TabItem(icon: Icons.event_outlined, activeIcon: Icons.event, label: 'Events', path: '/events'),
    _TabItem(icon: Icons.search_outlined, activeIcon: Icons.search, label: 'Lost & Found', path: '/lost-found'),
    _TabItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile', path: '/profile'),
  ];

  int _currentIndex(String location) {
    if (location.startsWith('/marketplace')) return 1;
    if (location.startsWith('/events')) return 2;
    if (location.startsWith('/lost-found')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final currentIndex = _currentIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.white,
          border: const Border(top: BorderSide(color: Color(0xFFEEEEEE))),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 56,
            child: Row(
              children: _tabs.asMap().entries.map((entry) {
                final i = entry.key;
                final tab = entry.value;
                final selected = currentIndex == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => context.go(tab.path),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          selected ? tab.activeIcon : tab.icon,
                          size: 22,
                          color: selected ? AppTheme.brandGreen : AppTheme.midGrey,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tab.label,
                          style: TextStyle(
                            fontSize: 10,
                            color: selected ? AppTheme.brandGreen : AppTheme.midGrey,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;

  const _TabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.path,
  });
}
