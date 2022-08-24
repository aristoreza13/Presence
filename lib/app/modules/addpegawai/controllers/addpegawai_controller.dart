import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddpegawaiController extends GetxController {
  RxBool isLoading = false.obs;
  RxBool isLoadingAddPegawai = false.obs;
  TextEditingController nameC = TextEditingController();
  TextEditingController jobC = TextEditingController();
  TextEditingController nipC = TextEditingController();
  TextEditingController emailC = TextEditingController();
  TextEditingController passAdminC = TextEditingController();

  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> prosesPegawai() async {
    if (passAdminC.text.isNotEmpty) {
      isLoadingAddPegawai.value = true;
      try {
        String emailAdmin = auth.currentUser!.email!;

        UserCredential adminCredential = await auth.signInWithEmailAndPassword(
            email: emailAdmin, password: passAdminC.text);
        UserCredential credential = await auth.createUserWithEmailAndPassword(
          email: emailC.text,
          password: "password",
          //? Password default, bisa diganti dengan memakai passC dengan TextEditingController
        );

        if (credential.user != null) {
          String uid = credential.user!.uid;

          await firestore.collection("pegawai").doc(uid).set({
            "nip": nipC.text,
            "name": nameC.text,
            "job": jobC.text,
            "email": emailC.text,
            "uid": uid,
            "role": "pegawai",
            "createdAt": DateTime.now().toIso8601String(),
          });

          await credential.user!.sendEmailVerification();

          await auth.signOut();

          UserCredential adminCredential =
              await auth.signInWithEmailAndPassword(
                  email: emailAdmin, password: passAdminC.text);

          Get.back();
          Get.back();
          Get.snackbar("Berhasil", "Pegawai sudah ditambahkan");
        }
        isLoadingAddPegawai.value = false;
      } on FirebaseAuthException catch (e) {
        isLoadingAddPegawai.value = false;
        if (e.code == 'weak-password') {
          Get.snackbar("Password Lemah", "Masukkan password yang kuat");
        } else if (e.code == 'email-already-in-use') {
          Get.snackbar("Email Sudah Ada", "Masukkan email yang lain");
        } else if (e.code == 'wrong-password') {
          Get.snackbar("Terjadi Kesalahan", "Password Salah !");
        } else {
          Get.snackbar("Terjadi Kesalahan", "${e.code}");
        }
      } catch (e) {
        isLoadingAddPegawai.value = false;
        Get.snackbar("Terjadi Kesalahan", "Tidak dapat menambahkan data");
      }
    } else {
      isLoading.value = false;
      Get.snackbar("Terjadi Kesalahan", "Password admin wajib diiisi");
    }
  }

  Future<void> addPegawai() async {
    if (nameC.text.isNotEmpty &&
        nipC.text.isNotEmpty &&
        jobC.text.isNotEmpty &&
        emailC.text.isNotEmpty) {
      isLoading.value = true;
      Get.defaultDialog(
          title: "Validasi Admin",
          content: Column(
            children: [
              const Text("Masukkan password untuk validasi admin!"),
              const SizedBox(
                height: 10,
              ),
              TextField(
                autocorrect: false,
                controller: passAdminC,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            OutlinedButton(
              onPressed: () {
                isLoading.value = false;
                Get.back();
              },
              child: Text("CANCEL"),
            ),
            Obx(
              () => ElevatedButton(
                onPressed: () async {
                  if (isLoadingAddPegawai.isFalse) {
                    await prosesPegawai();
                  }
                  isLoading.value = false;
                },
                child: Text(
                    isLoadingAddPegawai.isFalse ? "ADD PEGAWAI" : "LOADING..."),
              ),
            ),
          ]);
    } else {
      Get.snackbar("Terjadi Kesalahan", "Data harus diisikan");
    }
  }
}
