import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app/bindings/initial_binding.dart';
import 'app/routes.dart';
import 'core/services/hive_service.dart';
import 'presentation/home/home_screen.dart';
import 'presentation/scanner/scanner_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final needsRebuild = await HiveService.init();
  runApp(FoodCalorieApp(needsCacheRebuild: needsRebuild));
}

class FoodCalorieApp extends StatelessWidget {
  const FoodCalorieApp({super.key, required this.needsCacheRebuild});

  final bool needsCacheRebuild;

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
      initialRoute: AppRoutes.home,
      getPages: [
        GetPage(name: AppRoutes.home, page: () => const HomeScreen()),
        GetPage(name: AppRoutes.scanner, page: () => const ScannerScreen()),
      ],
    );
  }
}
