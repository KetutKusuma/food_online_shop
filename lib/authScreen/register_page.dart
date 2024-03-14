import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:food_online_shop/mainScreen/home_page.dart';
import 'package:food_online_shop/widgets/custom_text_form_field.dart';
import 'package:food_online_shop/widgets/error_dialog.dart';
import 'package:food_online_shop/widgets/loading_dialog.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as fStorage;
import 'package:shared_preferences/shared_preferences.dart';

import '../global/global.dart';

class RegisterPage extends StatefulWidget {
  RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController locationController = TextEditingController();

  XFile? imageXFile;
  String completeAdress = "";
  String sellerImageUrl = "";

  final ImagePicker _picker = ImagePicker();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Position? position;
  List<Placemark>? placeMark;

  Future<void> _getImage() async {
    imageXFile = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      imageXFile;
    });
  }

  getChange() async {
    String mama = "MAMA";
    emailController.text = mama;
  }

  getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    Position newPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    print(newPosition.latitude);
    print(newPosition.longitude);
    position = newPosition;

    try {
      placeMark = await placemarkFromCoordinates(
        position!.latitude,
        position!.longitude,
      );

      Placemark pMark = placeMark![0];
//nama addres seperti jl mana :
      completeAdress =
          '${pMark.subThoroughfare} ${pMark.thoroughfare}, ${pMark.subLocality} ${pMark.locality}, ${pMark.subAdministrativeArea}, ${pMark.administrativeArea} ${pMark.postalCode},${pMark.country}';
      print(completeAdress);

      locationController.text = completeAdress;
    } catch (e) {
      print(e);
    }
  }

  Future<void> formValidation() async {
    if (imageXFile == null) {
      showDialog(
        context: context,
        builder: (context) {
          return ErrorDialog(message: "Please selecet an image");
        },
      );
    } else {
      if (passwordController.text == confirmPasswordController.text) {
        if (confirmPasswordController.text.isNotEmpty &&
            emailController.text.isNotEmpty &&
            nameController.text.isNotEmpty &&
            phoneController.text.isNotEmpty &&
            locationController.text.isNotEmpty) {
          //start uploading image
          showDialog(
            context: context,
            builder: (c) {
              return LoadingDialog(
                message: "Registering Account",
              );
            },
          );
          String fileName = DateTime.now().millisecondsSinceEpoch.toString();
          fStorage.Reference reference = fStorage.FirebaseStorage.instance
              .ref()
              .child("sellers")
              .child(fileName);
          fStorage.UploadTask uploadTask =
              reference.putFile(File(imageXFile!.path));
          fStorage.TaskSnapshot taskSnapshot =
              await uploadTask.whenComplete(() {});
          await taskSnapshot.ref.getDownloadURL().then((url) {
            sellerImageUrl = url;

            //save info to firestore
            authenticateSellerAndSignUp();
          });
        } else {
          showDialog(
            context: context,
            builder: (context) {
              return ErrorDialog(
                  message:
                      "Please write the complete required info for Registration");
            },
          );
        }
      } else {
        showDialog(
          context: context,
          builder: (context) {
            return ErrorDialog(message: "Password do not match ");
          },
        );
      }
    }
  }

  Future<void> authenticateSellerAndSignUp() async {
    User? currentUser;

    try {
      await firebaseAuth
          .createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      )
          .then((auth) {
        currentUser = auth.user;
        print("ini user : " + currentUser.toString());
      });
    } on FirebaseAuthException catch (error) {
      Navigator.pop(context);
      showDialog(
          context: context,
          builder: (e) {
            return ErrorDialog(message: error.message.toString());
          });
    }

    // .catchError((error) {
    //   Navigator.pop(context);
    //   showDialog(
    //       context: context,
    //       builder: (c) {
    //         // print(error.message.toString());
    //         return ErrorDialog(message: error.message.toString());
    //       });
    // });
    if (currentUser != null) {
      saveDataToFirestore(currentUser!).then((value) {
        Navigator.pop(context);

        //send user to homepage
        Route newRoute = MaterialPageRoute(builder: (c) {
          return HomePage();
        });
        Navigator.pushReplacement(context, newRoute);
      });
    }
  }

  Future saveDataToFirestore(User currentUser) async {
    FirebaseFirestore.instance.collection("sellers").doc(currentUser.uid).set({
      "sellerUID": currentUser.uid,
      "sellerEmail": currentUser.email,
      "sellerName": nameController.text.trim(),
      "sellerAvatarUrl": sellerImageUrl,
      "phone": phoneController.text.trim(),
      "address": completeAdress,
      "status": "approve",
      "earnings": 0.0,
      "lat": position!.latitude,
      "lng": position!.longitude,
    });

    //save data locally
    sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences!.setString("uid", currentUser.uid);
    await sharedPreferences!.setString("email", currentUser.email.toString());
    await sharedPreferences!.setString("name", nameController.text.trim());
    await sharedPreferences!.setString("photoUrl", sellerImageUrl);
  }

  TextInputType nameKeyboard = TextInputType.name;
  TextInputType emailKeyboard = TextInputType.emailAddress;
  TextInputType phoneKeyboard = TextInputType.phone;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            SizedBox(
              height: 10,
            ),
            InkWell(
              onTap: () {
                _getImage();
              },
              child: CircleAvatar(
                radius: MediaQuery.of(context).size.width * 0.20,
                backgroundColor: Colors.white,
                backgroundImage: imageXFile == null
                    ? null
                    : FileImage(
                        File(imageXFile!.path),
                      ),
                child: imageXFile == null
                    ? Icon(
                        Icons.add_photo_alternate_outlined,
                        size: MediaQuery.of(context).size.width * 0.20,
                        color: Colors.grey,
                      )
                    : null,
              ),
            ),
            SizedBox(
              height: 15,
            ),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  CustomTextFormField(
                    keyBoardType: nameKeyboard,
                    textEditingController: nameController,
                    hintText: "Name",
                    iconData: Icons.person_rounded,
                    isObsecre: false,
                  ),
                  CustomTextFormField(
                    keyBoardType: emailKeyboard,
                    textEditingController: emailController,
                    hintText: "Email",
                    iconData: Icons.email_rounded,
                    isObsecre: false,
                  ),
                  CustomTextFormField(
                    keyBoardType: nameKeyboard,
                    textEditingController: passwordController,
                    hintText: "Password",
                    iconData: Icons.lock_rounded,
                    isObsecre: true,
                  ),
                  CustomTextFormField(
                    keyBoardType: nameKeyboard,
                    textEditingController: confirmPasswordController,
                    hintText: "Confrim Password",
                    iconData: Icons.lock_rounded,
                    isObsecre: true,
                  ),
                  CustomTextFormField(
                    keyBoardType: phoneKeyboard,
                    textEditingController: phoneController,
                    hintText: "Phone",
                    iconData: Icons.phone_rounded,
                    isObsecre: false,
                  ),
                  CustomTextFormField(
                    keyBoardType: nameKeyboard,
                    textEditingController: locationController,
                    iconData: Icons.location_on_rounded,
                    hintText: "Cafe/Restaurant Address",
                    isObsecre: false,
                    enabled: false,
                  ),
                  Container(
                    width: 400,
                    height: 40,
                    alignment: Alignment.center,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        getCurrentLocation();
                      },
                      icon: Icon(Icons.my_location_rounded),
                      label: Text(
                        "Find My Current Location",
                        style: GoogleFonts.varta(
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        primary: Colors.amber,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
            SizedBox(
              height: 20,
            ),
            ElevatedButton(
              onPressed: () {
                // if (_formKey.currentState!.validate()) {
                //   ScaffoldMessenger.of(context)
                //       .showSnackBar(SnackBar(content: Text("Berhasil Boy")));
                // } else {
                //   ScaffoldMessenger.of(context)
                //       .showSnackBar(SnackBar(content: Text("Gagal Boy")));
                // }
                formValidation();
              },
              child: Text(
                "Sign Up",
                style: GoogleFonts.varela(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                primary: Colors.cyan.shade600,
                padding: EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 60,
                ),
              ),
            ),
            SizedBox(
              height: 10,
            )
          ],
        ),
      ),
    );
  }
}
