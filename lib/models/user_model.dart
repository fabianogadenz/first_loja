import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:flutter/material.dart';

class UserModel extends Model{

  FirebaseAuth _auth = FirebaseAuth.instance;

  FirebaseUser firebaseUser;
  Map<String, dynamic> userData = Map();

  bool isLoading = false;


  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
  }

  void signUp({@required Map<String, dynamic> userData, @required String pass,
    @required VoidCallback onSuccess, @required VoidCallback onFail}){

    isLoading = true;
    notifyListeners();

    _auth.createUserWithEmailAndPassword(
        email: userData["email"],
        password: pass
    ).then((user) async {
      this.firebaseUser = user;

      await _saveUserData(userData);
      
      onSuccess();
      isLoading = false;
      print("sucesso");
      notifyListeners();
    }).catchError((e){
      print(e);
      onFail();
      isLoading = false;
      notifyListeners();
    });

  }

  void signIn({@required String email, @required String pass,
    @required VoidCallback onSuccess, @required VoidCallback onFail}) async{
    isLoading = true;
    notifyListeners();

    _auth.signInWithEmailAndPassword(email: email, password: pass).then(
        (user) async{
          this.firebaseUser = user;

          await _loadCurrentUser();

          onSuccess();
          isLoading = false;
          notifyListeners();

        }).catchError((e){
          onFail();
          isLoading = false;
          notifyListeners();
    });

  }
  void recoverPass(String email){
    _auth.sendPasswordResetEmail(email: email);
  }

  void signOut() async{
    await _auth.signOut();

    userData = Map();
    this.firebaseUser = null;
    notifyListeners();
  }

  bool isLoggedIn(){
    return firebaseUser != null;
  }

  Future<Null> _saveUserData(Map<String, dynamic> userData) async{
    this.userData = userData;
    await Firestore.instance.collection("users").document(this.firebaseUser.uid).setData(userData);
  }

  Future<Null> _loadCurrentUser() async {
    if(this.firebaseUser == null)
      this.firebaseUser = await _auth.currentUser();
    if(this.firebaseUser != null){
      if(userData["name"] == null){
        DocumentSnapshot docUser =
          await Firestore.instance.collection("users").document(this.firebaseUser.uid).get();
        userData = docUser.data;
      }
    }
    notifyListeners();
  }
}