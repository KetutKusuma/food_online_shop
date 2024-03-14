import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:food_online_shop/authScreen/auth_page.dart';
import 'package:food_online_shop/global/global.dart';
import 'package:food_online_shop/mainScreen/home_page.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  startTimer() {
    Timer(const Duration(seconds: 5), () async {
      //cek seller sudah login atau belum
      if (firebaseAuth.currentUser != null) {
        Navigator.push(context, MaterialPageRoute(builder: ((context) {
          return const HomePage();
        })));
      } else {
        Navigator.push(context, MaterialPageRoute(builder: ((context) {
          return const AuthPage();
        })));
      }
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    startTimer();
  }

  Widget build(BuildContext context) {
    return Material(
      child: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("image/splash.png"),
            SizedBox(
              height: 10,
            ),
            Text("Food Online Shop",
                style: GoogleFonts.varela(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                  wordSpacing: 0.2,
                  color: Colors.black54,
                ))
          ],
        ),
      ),
    );
  }
}
