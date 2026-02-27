import 'package:get/get.dart';

class MainController extends GetxController {
  MainController({int initialIndex = 0}) {
    currentIndex.value = initialIndex;
  }

  final currentIndex = 0.obs;

  void changePage(int index) {
    currentIndex.value = index;
  }
}
