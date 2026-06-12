import 'package:go_router/go_router.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/verify_email_screen.dart';
import '../../features/onboarding/screens/brand/brand_info_screen.dart';
import '../../features/onboarding/screens/brand/brand_social_screen.dart';
import '../../features/onboarding/screens/brand/brand_industries_screen.dart';
import '../../features/onboarding/screens/creator/creator_info_screen.dart';
import '../../features/onboarding/screens/creator/creator_social_screen.dart';
import '../../features/onboarding/screens/creator/creator_categories_screen.dart';
import '../../features/onboarding/screens/success_screen.dart';
import '../../features/brand/screens/brand_shell.dart';
import '../../features/brand/screens/announcements_screen.dart';
import '../../features/brand/screens/collaborations_screen.dart';
import '../../features/brand/screens/creators_screen.dart';
import '../../features/brand/screens/profile_screen.dart';
import '../../features/brand/screens/create_announcement_screen.dart';
import '../../features/brand/screens/edit_announcement_screen.dart';
import '../../features/brand/screens/announcement_details_screen.dart';
import '../../features/brand/screens/application_details_screen.dart';
import '../../features/brand/screens/collaboration_details_screen.dart';
import '../../features/creator/screens/creator_shell.dart';
import '../../features/creator/screens/creator_announcements_screen.dart';
import '../../features/creator/screens/creator_applications_screen.dart';
import '../../features/creator/screens/creator_collaborations_screen.dart';
import '../../features/creator/screens/creator_profile_screen.dart';
import '../../features/creator/screens/creator_announcement_details_screen.dart';
import '../../features/creator/screens/creator_application_details_screen.dart';
import '../../features/creator/screens/creator_apply_screen.dart';
import '../../features/creator/screens/creator_collaboration_details_screen.dart';
import '../../features/shared/screens/notifications_screen.dart';

class AppRouter {
  static GoRouter router(AuthProvider authProvider) {
    return GoRouter(
      refreshListenable: authProvider,
      initialLocation: '/login',
      redirect: (context, state) {
        final isLoading = authProvider.isLoading;
        if (isLoading) return null;

        final isAuthenticated = authProvider.isAuthenticated;
        final isVerified = authProvider.isEmailVerified;
        final isOnboarded = authProvider.isOnboarded;
        final userType = authProvider.user?.type;

        final currentPath = state.uri.path;
        final isOnAuthPage =
            currentPath.startsWith('/login') ||
            currentPath.startsWith('/signup');
        final isOnVerifyPage = currentPath == '/verify-email';
        final isOnOnboarding = currentPath.startsWith('/onboarding');
        final isOnSuccess = currentPath == '/onboarding/success';

        // Not authenticated → login
        if (!isAuthenticated) {
          return isOnAuthPage ? null : '/login';
        }

        // Authenticated but not verified → verify email
        if (!isVerified) {
          return isOnVerifyPage ? null : '/verify-email';
        }

        // Verified but not onboarded → onboarding
        if (!isOnboarded && !isOnOnboarding) {
          if (userType == UserType.brand) {
            return '/onboarding/brand/info';
          } else {
            return '/onboarding/creator/info';
          }
        }

        // Fully authenticated → main app
        if (isVerified &&
            isOnboarded &&
            (isOnAuthPage ||
                isOnVerifyPage ||
                (isOnOnboarding && !isOnSuccess))) {
          if (userType == UserType.brand) {
            return '/brand/announcements';
          } else {
            return '/creator/announcements';
          }
        }

        return null;
      },
      routes: [
        // ─── Auth Routes ───
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignupScreen(),
        ),
        GoRoute(
          path: '/verify-email',
          builder: (context, state) => const VerifyEmailScreen(),
        ),

        // ─── Onboarding Routes ───
        GoRoute(
          path: '/onboarding/brand/info',
          builder: (context, state) => const BrandInfoScreen(),
        ),
        GoRoute(
          path: '/onboarding/brand/social',
          builder: (context, state) => const BrandSocialScreen(),
        ),
        GoRoute(
          path: '/onboarding/brand/industries',
          builder: (context, state) => const BrandIndustriesScreen(),
        ),
        GoRoute(
          path: '/onboarding/creator/info',
          builder: (context, state) => const CreatorInfoScreen(),
        ),
        GoRoute(
          path: '/onboarding/creator/social',
          builder: (context, state) => const CreatorSocialScreen(),
        ),
        GoRoute(
          path: '/onboarding/creator/categories',
          builder: (context, state) => const CreatorCategoriesScreen(),
        ),
        GoRoute(
          path: '/onboarding/success',
          builder: (context, state) => const OnboardingSuccessScreen(),
        ),

        // ─── Brand Routes (ShellRoute for bottom nav) ───
        ShellRoute(
          builder: (context, state, child) => BrandShell(child: child),
          routes: [
            GoRoute(
              path: '/brand/announcements',
              builder: (context, state) => const BrandAnnouncementsScreen(),
            ),
            GoRoute(
              path: '/brand/collaborations',
              builder: (context, state) => const BrandCollaborationsScreen(),
            ),
            GoRoute(
              path: '/brand/creators',
              builder: (context, state) => const BrandCreatorsScreen(),
            ),
            GoRoute(
              path: '/brand/profile',
              builder: (context, state) => const BrandProfileScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/brand/create-announcement',
          builder: (context, state) => const CreateAnnouncementScreen(),
        ),
        GoRoute(
          path: '/brand/edit-announcement/:id',
          builder: (_, state) => EditAnnouncementScreen(
            id: int.parse(state.pathParameters['id']!),
          ),
        ),
        GoRoute(
          path: '/brand/announcement/:id',
          builder: (_, state) => BrandAnnouncementDetailsScreen(
            id: int.parse(state.pathParameters['id']!),
          ),
        ),
        GoRoute(
          path: '/brand/application/:id',
          builder: (_, state) => BrandApplicationDetailsScreen(
            id: int.parse(state.pathParameters['id']!),
          ),
        ),
        GoRoute(
          path: '/brand/collaboration/:id',
          builder: (_, state) => BrandCollaborationDetailsScreen(
            id: int.parse(state.pathParameters['id']!),
          ),
        ),

        // ─── Creator Routes (ShellRoute for bottom nav) ───
        ShellRoute(
          builder: (context, state, child) => CreatorShell(child: child),
          routes: [
            GoRoute(
              path: '/creator/announcements',
              builder: (context, state) => const CreatorAnnouncementsScreen(),
            ),
            GoRoute(
              path: '/creator/applications',
              builder: (context, state) => const CreatorApplicationsScreen(),
            ),
            GoRoute(
              path: '/creator/collaborations',
              builder: (context, state) => const CreatorCollaborationsScreen(),
            ),
            GoRoute(
              path: '/creator/profile',
              builder: (context, state) => const CreatorProfileScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/creator/announcement/:id',
          builder: (_, state) => CreatorAnnouncementDetailsScreen(
            id: int.parse(state.pathParameters['id']!),
          ),
        ),
        GoRoute(
          path: '/creator/application/:id',
          builder: (_, state) => CreatorApplicationDetailsScreen(
            id: int.parse(state.pathParameters['id']!),
          ),
        ),
        GoRoute(
          path: '/creator/apply/:id',
          builder: (_, state) =>
              CreatorApplyScreen(id: int.parse(state.pathParameters['id']!)),
        ),
        GoRoute(
          path: '/creator/collaboration/:id',
          builder: (_, state) => CreatorCollaborationDetailsScreen(
            id: int.parse(state.pathParameters['id']!),
          ),
        ),

        // ─── Shared Routes ───
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
      ],
    );
  }
}
