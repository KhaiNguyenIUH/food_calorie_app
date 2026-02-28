import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:liquid_tabbar_minimize/liquid_tabbar_minimize.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/bindings/initial_binding.dart';
import 'app/routes.dart';
import 'core/constants/app_config.dart';
import 'data/repositories/user_profile_repository.dart';
import 'core/services/hive_service.dart';
import 'presentation/main/main_screen.dart';
import 'presentation/scanner/scanner_screen.dart';
import 'presentation/onboarding/onboarding_screen.dart';
import 'presentation/notifications/notifications_screen.dart';
import 'presentation/activity/activity_screen.dart';
import 'presentation/activity/activity_detail_screen.dart';
import 'presentation/profile/profile_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase for anonymous auth
  if (AppConfig.supabaseUrl.isNotEmpty) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  }

  final needsRebuild = await HiveService.init();
  final profileRepo = UserProfileRepository();
  final hasProfile = profileRepo.hasProfile;
  runApp(
    FoodCalorieApp(needsCacheRebuild: needsRebuild, hasProfile: hasProfile),
  );
}

class FoodCalorieApp extends StatelessWidget {
  const FoodCalorieApp({
    super.key,
    required this.needsCacheRebuild,
    required this.hasProfile,
  });

  final bool needsCacheRebuild;
  final bool hasProfile;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Food Calorie App',
      debugShowCheckedModeBanner: false,
      initialBinding: InitialBinding(needsCacheRebuild: needsCacheRebuild),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        useMaterial3: true,
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      navigatorObservers: [LiquidRouteObserver.instance],
      initialRoute: hasProfile ? AppRoutes.main : AppRoutes.onboarding,
      getPages: [
        GetPage(name: AppRoutes.main, page: () => const MainScreen()),
        GetPage(
          name: AppRoutes.home,
          page: () => const MainScreen(initialIndex: 0),
        ),
        GetPage(
          name: AppRoutes.onboarding,
          page: () => const OnboardingScreen(),
        ),
        GetPage(name: AppRoutes.scanner, page: () => const ScannerScreen()),
        GetPage(
          name: AppRoutes.notifications,
          page: () => const NotificationsScreen(),
        ),
        GetPage(
          name: AppRoutes.plan,
          page: () => const MainScreen(initialIndex: 1),
        ),
        GetPage(name: AppRoutes.activity, page: () => const ActivityScreen()),
        GetPage(
          name: AppRoutes.activityDetail,
          page: () => const ActivityDetailScreen(),
        ),
        GetPage(name: AppRoutes.profile, page: () => const ProfileScreen()),
      ],
    );
  }
}
