import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class LocationProvider with ChangeNotifier {
  Future<void> startFireBase() async {
    print("Starting firebase .......");

    await Firebase.initializeApp();
  }

  Future<bool> checkInternetConnection() async {
    try {
      await InternetAddress.lookup('google.com');
      //Nothing to do --> continue in code
    } on SocketException catch (_) {
      return false;
    }
    return true;
  }

  Future<String> fetchAndSetFromFirebase(
      {required BuildContext context}) async {
    // Check internet connection
    bool check = await checkInternetConnection();

    if (!check) {
      return "noInternetConnection";
    }

    FirebaseFirestore fCF;

    try {
      // Intialize firebase
      await startFireBase();
      // login user
      fCF = FirebaseFirestore.instance;
      QuerySnapshot snap;
      snap = await fCF
          .collection("App")
          .doc("AppProducts")
          .collection("Products")
          .get();

      // downloadedProducts = snap.docs;

      return '';
    } on SocketException catch (_) {
      return "noInternetConnection";
    } catch (e) {
      return "anErrorOccurred";
    }
  }

  Future<String> updateCoordinatesInFirebase({
    required BuildContext context,
    required String latitude,
    required String longitude,
  }) async {
    // Check internet connection
    bool check = await checkInternetConnection();

    if (!check) {
      return "noInternetConnection";
    }

    FirebaseFirestore fCF;

    try {
      // Intialize firebase
      await startFireBase();
      // login user
      fCF = FirebaseFirestore.instance;
      await fCF.collection("Coordinates").doc("InitialDocument").update(
        {
          'Latitude': latitude,
          'Longitude': longitude,
        },
      );

      // downloadedProducts = snap.docs;

      return '';
    } on SocketException catch (_) {
      return "noInternetConnection";
    } catch (e) {
      return "anErrorOccurred";
    }
  }
}
