import 'package:get/get.dart';

class CoreController extends GetxController {
  var currentIndex = 1.obs;

  void changeIndex(int index) {
    currentIndex.value = index;
  }
}