import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ultralytics_yolo_example/presentation/screens/main_navigation_screen.dart';

class LoginScreen extends StatefulWidget {
 const LoginScreen({Key? key}) : super(key: key);
 
 @override
 State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
 
  Duration get loginTime => const Duration(milliseconds: 2250);

  Future<String?> _authUser(LoginData data) async {
  debugPrint('Name: ${data.name}, Password: ${data.password}');
  try {
      // login ke Firebase
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: data.name,
        password: data.password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase login error: ${e.code}');
      if (e.code == 'user-not-found') {
        return 'User not exists';
      } else if (e.code == 'wrong-password') {
        return 'Password does not match';
      } else {
        return 'Login failed: ${e.message}';
      }
    } catch (e) {
      debugPrint('Unknown error: $e');
      return 'Login failed';
    }
  }

  Future<String?> _signupUser(SignupData data) async {
    debugPrint('Signup Name: ${data.name}, Password: ${data.password}');
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: data.name!,
        password: data.password!,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        return 'The password provided is too weak';
      } else if (e.code == 'email-already-in-use') {
        return 'The account already exists for that email';
      }
      return 'Registration failed: ${e.message}';
    } catch (e) {
      return 'Registration failed';
    }
  }

  Future<String> _recoverPassword(String name) async {
    debugPrint('Name: $name');
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: name);
      return '';
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'User not found';
      }
      return 'Password recovery failed: ${e.message}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FlutterLogin(
      title: 'SunyaAksara',
      logo: const AssetImage('assets/sign_logo.png'),
      onLogin: _authUser,
      onSignup: _signupUser,
      onSubmitAnimationCompleted: () {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => const MainNavigationScreen(),
        ));
      },
      onRecoverPassword: _recoverPassword,
    );
  }
}
