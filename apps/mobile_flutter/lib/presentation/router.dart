import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/sites/sites_list_screen.dart';
import 'screens/sites/create_site_screen.dart';
import 'screens/sites/site_detail_screen.dart';
import 'screens/hives/hive_list_screen.dart';
import 'screens/hives/create_hive_screen.dart';
import 'screens/hives/hive_detail_screen.dart';
import 'screens/inspection/quick_inspection_screen.dart';
import 'screens/community/community_feed_screen.dart';
import 'screens/community/create_post_screen.dart';
import 'screens/community/post_detail_screen.dart';
import 'screens/community/channels_screen.dart';
import 'screens/community/groups_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/varroa/varroa_measurement_screen.dart';
import 'screens/varroa/treatment_screen.dart';
import 'screens/varroa/varroa_history_screen.dart';
import 'screens/voice/voice_entry_screen.dart';
import 'screens/hives/hive_tasks_screen.dart';
import 'screens/tools/calculator_screen.dart';
import 'screens/tools/calendar_screen.dart';
import 'screens/ai/ai_assistant_screen.dart';

class AppRouter {
  final AuthProvider authProvider;
  final String initialLocation;

  AppRouter({required this.authProvider, this.initialLocation = '/home'});

  late final GoRouter router = GoRouter(
    initialLocation: initialLocation,
    refreshListenable: authProvider,
    redirect: (BuildContext context, GoRouterState state) {
      final isLoggedIn = authProvider.isLoggedIn;
      final location = state.matchedLocation;
      final isLoginRoute = location == '/login';
      final isRegisterRoute = location == '/register';
      final isCommunityRoute = location == '/community' ||
          location.startsWith('/community/');

      // Redirect to login only for community routes when not logged in
      if (!isLoggedIn && isCommunityRoute) {
        return '/login?redirect=$location';
      }

      // If logged in and on login/register, go home
      if (isLoggedIn && (isLoginRoute || isRegisterRoute)) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => HomeScreen(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomeTabContent(),
          ),
          GoRoute(
            path: '/sites',
            name: 'sites',
            builder: (context, state) => const SitesListScreen(),
            routes: [
              GoRoute(
                path: 'create',
                name: 'create-site',
                builder: (context, state) => const CreateSiteScreen(),
              ),
              GoRoute(
                path: ':siteId',
                name: 'site-detail',
                builder: (context, state) {
                  final siteId =
                      int.tryParse(state.pathParameters['siteId'] ?? '') ?? 0;
                  return SiteDetailScreen(siteId: siteId);
                },
                routes: [
                  GoRoute(
                    path: 'hives',
                    name: 'site-hives',
                    builder: (context, state) {
                      final siteId =
                          int.tryParse(state.pathParameters['siteId'] ?? '') ??
                              0;
                      return HiveListScreen(siteId: siteId);
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/community',
            name: 'community',
            builder: (context, state) => const CommunityTabScreen(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      // Hive routes (outside shell for full-screen navigation)
      GoRoute(
        path: '/hives/create/:siteId',
        name: 'create-hive',
        builder: (context, state) {
          final siteId =
              int.tryParse(state.pathParameters['siteId'] ?? '') ?? 0;
          return CreateHiveScreen(siteId: siteId);
        },
      ),
      GoRoute(
        path: '/hives/:hiveId',
        name: 'hive-detail',
        builder: (context, state) {
          final hiveId =
              int.tryParse(state.pathParameters['hiveId'] ?? '') ?? 0;
          return HiveDetailScreen(hiveId: hiveId);
        },
      ),
      GoRoute(
        path: '/hives/:hiveId/inspect',
        name: 'quick-inspection',
        builder: (context, state) {
          final hiveId =
              int.tryParse(state.pathParameters['hiveId'] ?? '') ?? 0;
          return QuickInspectionScreen(hiveId: hiveId);
        },
      ),
      // Varroa routes
      GoRoute(
        path: '/hives/:hiveId/varroa',
        name: 'varroa-measurement',
        builder: (context, state) {
          final hiveId = state.pathParameters['hiveId'] ?? '0';
          return VarroaMeasurementScreen(hiveId: hiveId);
        },
      ),
      GoRoute(
        path: '/hives/:hiveId/treatment',
        name: 'treatment',
        builder: (context, state) {
          final hiveId = state.pathParameters['hiveId'] ?? '0';
          return TreatmentScreen(hiveId: hiveId);
        },
      ),
      GoRoute(
        path: '/hives/:hiveId/varroa-history',
        name: 'varroa-history',
        builder: (context, state) {
          final hiveId = state.pathParameters['hiveId'] ?? '0';
          return VarroaHistoryScreen(hiveId: hiveId);
        },
      ),
      // Per-hive tasks
      GoRoute(
        path: '/hives/:hiveId/tasks',
        name: 'hive-tasks',
        builder: (context, state) {
          final hiveId =
              int.tryParse(state.pathParameters['hiveId'] ?? '') ?? 0;
          return HiveTasksScreen(hiveId: hiveId);
        },
      ),
      // Tools
      GoRoute(
        path: '/tools/calculator',
        name: 'calculator',
        builder: (context, state) => const CalculatorScreen(),
      ),
      GoRoute(
        path: '/tools/calendar',
        name: 'calendar',
        builder: (context, state) => const CalendarScreen(),
      ),
      // Voice entry
      GoRoute(
        path: '/voice',
        name: 'voice-entry',
        builder: (context, state) => const VoiceEntryScreen(),
      ),
      // AI assistant
      GoRoute(
        path: '/ai',
        name: 'ai-assistant',
        builder: (context, state) => const AiAssistantScreen(),
      ),
      // Community detail routes
      GoRoute(
        path: '/community/create',
        name: 'create-post',
        builder: (context, state) => const CreatePostScreen(),
      ),
      GoRoute(
        path: '/community/:postId',
        name: 'post-detail',
        builder: (context, state) {
          final postId = state.pathParameters['postId'] ?? '';
          return PostDetailScreen(postId: postId);
        },
      ),
      GoRoute(
        path: '/community/groups',
        name: 'groups',
        builder: (context, state) => const GroupsScreen(),
      ),
    ],
  );
}
