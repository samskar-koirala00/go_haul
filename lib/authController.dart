import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_haul/utils/extension.dart';

enum Status { uninitialized, authenticated, authenticating, unauthenticated }

class Auth extends GetxController {
  final Future<SharedPreferences> _preferences =
      SharedPreferences.getInstance();
  FirebaseAuth? _auth;
  User? _user;
  String? userData;
  Status _status = Status.uninitialized;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TextEditingController name = TextEditingController();

  Status get status => _status;
  User? get user => _user;

  Auth.initialize() : _auth = FirebaseAuth.instance {
    _auth?.authStateChanges().listen((event) {
      _onStateChanged(event!);
    });
  }

  Future<bool> signIn({required String email, password}) async {
    try {
      var details = FirebaseFirestore.instance
          .collection("users")
          .doc(Get.find<Auth>().userData as String);
      final SharedPreferences prefs = await _preferences;
      _status = Status.authenticating;
      await _auth
          ?.signInWithEmailAndPassword(
              email: email.trim(), password: password.trim())
          .then((result) {
        // _firestore.collection('users').doc(result.user?.uid).set({
        //   'name': email,
        //   'email': email,
        //   'uid': result.user?.uid,
        //   "verified": details.get()['updated'],
        //   "pwd": password,
        //   "history": []
        // });
        prefs.setString("UID", result.user?.uid as String);
        userData = result.user?.uid as String;
      });
      return true;
    } catch (e) {
      _status = Status.unauthenticated;
      return false;
    }
  }

  Future<bool> signUp({required String email, password}) async {
    try {
      final SharedPreferences prefs = await _preferences;
      _status = Status.authenticating;
      await _auth!
          .createUserWithEmailAndPassword(email: email, password: password)
          .then((result) {
        _firestore.collection('users').doc(result.user?.uid).set({
          'name': email,
          'email': email,
          'uid': result.user?.uid,
          "verified": false,
          "pwd": password,
          "history": [],
          "token": ""
        });
        prefs.setString("UID", result.user?.uid as String);
        userData = result.user?.uid as String;
      });
      return true;
    } catch (e) {
      _status = Status.unauthenticated;
      return false;
    }
  }

  Future<void> _onStateChanged(User firebaseUser) async {
    _user = firebaseUser;
    _status = Status.authenticated;
  }

  void clearController() {
    name.text = "";
  }

  Future signOut() async {
    _auth?.signOut();
    _status = Status.unauthenticated;

    //return Future.delayed(Duration.zero);
  }
}
