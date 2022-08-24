import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:presence_app/app/routes/app_pages.dart';

class PageIndexController extends GetxController {
  RxInt pageIndex = 0.obs;

  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  void changePage(int i) async {
    switch (i) {
      case 1:
        Map<String, dynamic> dataResponse = await determinePosition();
        if (dataResponse["error"] != true) {
          Position position = dataResponse["position"];
          List<Placemark> placemarks = await placemarkFromCoordinates(
              position.latitude, position.longitude);
          String address =
              "${placemarks[0].street}, ${placemarks[0].locality}, ${placemarks[0].administrativeArea}";
          await updatePosition(position, address);

          // cek distance
          double distance = Geolocator.distanceBetween(
              -7.5563347, 110.7721992, position.latitude, position.longitude);

          // presensi
          await presensi(position, address, distance);
          Get.snackbar("Berhasil", "Sudah mengisi daftar hadir");
        } else {
          Get.snackbar("Terjadi kesalahan", dataResponse["message"]);
        }
        break;
      case 2:
        pageIndex.value = i;
        Get.offAllNamed(Routes.PROFILE);
        break;
      default:
        pageIndex.value = i;
        Get.offAllNamed(Routes.HOME);
    }
  }

  Future<void> presensi(
      Position position, String address, double distance) async {
    String uid = await auth.currentUser!.uid;

    CollectionReference<Map<String, dynamic>> colPresence =
        await firestore.collection("pegawai").doc(uid).collection("presensi");

    QuerySnapshot<Map<String, dynamic>> snapPresence = await colPresence.get();

    DateTime date = DateTime.now();
    String docDate = DateFormat.yMd().format(date).replaceAll("/", "-");

    String status = "Di luar area";

    if (distance <= 200) {
      status = "Di dalam area";
    }

    if (snapPresence.docs.length == 0) {
      // belum pernah absen
      await colPresence.doc(docDate).set({
        "date": date.toIso8601String(),
        "masuk": {
          "date": date.toIso8601String(),
          "lat": position.latitude,
          "long": position.longitude,
          "address": address,
          "status": status,
          "distance": distance
        },
      });
    } else {
      // sudah absen -> cek udah absen masuk/keluar belum?
      DocumentSnapshot<Map<String, dynamic>> todayDoc =
          await colPresence.doc(docDate).get();

      if (todayDoc.exists == true) {
        // Sudah absen, tinggal keluar
        Map<String, dynamic>? dataMap = todayDoc.data();
        if (dataMap?["keluar"] != null) {
          // sudah absen masuk dan keluar
          Get.snackbar("Pemberitahuan",
              "Anda sudah absen keluar hari ini dan tidak dapat absen kembali");
        } else {
          // absen keluar
          await colPresence.doc(docDate).update({
            "keluar": {
              "date": date.toIso8601String(),
              "lat": position.latitude,
              "long": position.longitude,
              "address": address,
              "status": status,
              "distance": distance
            },
          });
        }
      } else {
        // absen masuk
        await colPresence.doc(docDate).set({
          "date": date.toIso8601String(),
          "masuk": {
            "date": date.toIso8601String(),
            "lat": position.latitude,
            "long": position.longitude,
            "address": address,
            "status": status,
            "distance": distance
          },
        });
      }
    }
  }

  Future<void> updatePosition(Position position, String address) async {
    String uid = await auth.currentUser!.uid;

    await firestore.collection("pegawai").doc(uid).update({
      "position": {
        "lat": position.latitude,
        "long": position.longitude,
      },
      "address": address,
    });
  }

  Future<Map<String, dynamic>> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      // return Future.error('Location services are disabled.');
      return {
        "message": "Tidak dapat mengambil GPS dari device ini.",
        "error": true,
      };
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        // return Future.error('Location permissions are denied');
        return {
          "message": "Izin menggunakan GPS ditolak.",
          "error": true,
        };
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return {
        "message":
            "Fitur lokasi tidak aktif. Silakan aktifkan terlebih dahulu.",
        "error": true,
      };
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    Position position = await Geolocator.getCurrentPosition();
    return {
      "position": position,
      "message": "Berhasil mendapat posisi device.",
      "error": false,
    };
  }
}
