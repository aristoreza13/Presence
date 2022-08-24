import 'package:get/get.dart';

import '../controllers/addpegawai_controller.dart';

class AddpegawaiBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AddpegawaiController>(
      () => AddpegawaiController(),
    );
  }
}
