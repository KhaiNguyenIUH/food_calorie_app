import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:liquid_tabbar_minimize/liquid_tabbar_minimize.dart';
import '../../core/theme/app_colors.dart';
import '../../app/routes.dart';
import '../home/home_screen.dart';
import '../plan/plan_screen.dart';
import 'main_controller.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    return GetX<MainController>(
      init: MainController(initialIndex: initialIndex),
      builder: (ctrl) {
        final background = ctrl.currentIndex.value == 0
            ? AppColors.homeBackground
            : AppColors.background;
        return Scaffold(
          extendBody: true,
          backgroundColor: background,
          body: IndexedStack(
            index: ctrl.currentIndex.value,
            children: const [HomeScreen(), PlanScreen(isEmbedded: true)],
          ),
          bottomNavigationBar: LiquidBottomNavigationBar(
            currentIndex: ctrl.currentIndex.value,
            onTap: ctrl.changePage,
            items: const [
              LiquidTabItem(
                widget: Icon(Icons.home_outlined),
                selectedWidget: Icon(Icons.home),
                sfSymbol: 'house',
                selectedSfSymbol: 'house.fill',
                label: 'Home',
              ),
              LiquidTabItem(
                widget: Icon(Icons.calendar_month_outlined),
                selectedWidget: Icon(Icons.calendar_month),
                sfSymbol: 'calendar',
                selectedSfSymbol: 'calendar',
                label: 'Plan',
              ),
            ],
            labelVisibility: LabelVisibility.always,
            selectedItemColor: AppColors.protein,
            unselectedItemColor: AppColors.textSecondary,
            showActionButton: true,
            actionButton: const ActionButtonConfig(Icon(Icons.add), 'plus'),
            onActionTap: () => Get.toNamed(AppRoutes.scanner),
            bottomOffset: 10,
            height: 66,
            enableMinimize: false,
            forceCustomBar: true,
          ),
        );
      },
    );
  }
}
