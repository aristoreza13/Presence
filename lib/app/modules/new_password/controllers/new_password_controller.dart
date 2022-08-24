import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:presence_app/app/routes/app_pages.dart';

class NewPasswordController extends GetxController {
  FirebaseAuth auth = FirebaseAuth.instance;
  TextEditingController newPassC = TextEditingController();

  void newPassword() async {
    if (newPassC.text.isNotEmpty) {
      if (newPassC.text != "password") {
        // 2 kondisi
        // 1. kalau tidak mau repot user login ulang
        // 2. kalau user diharuskan login ulang. pakai Get.offAllNamed(Routes.LOGIN);
        // setelah signOut();
        try {
          String email = auth.currentUser!.email!;
          await auth.currentUser!.updatePassword(newPassC.text);

          await auth.signOut();

          await auth.signInWithEmailAndPassword(
            email: email,
            password: newPassC.text,
          );
          Get.offAllNamed(Routes.HOME);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'weak-password') {
            Get.snackbar("Terjadi Kesalahan", "Minimal 6 karakter");
          }
        } catch (e) {
          Get.snackbar("Terjadi Kesalahan", "Tidak dapat membuat password");
        }
      } else {
        Get.snackbar("Terjadi Kesalahan", "Wajib mengganti password");
      }
    } else {
      Get.snackbar("Terjadi Kesalahan", "Wajib isi password baru");
    }
  }
}
