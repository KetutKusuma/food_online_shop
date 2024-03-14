import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';

class CustomTextFormField extends StatelessWidget {
  final TextEditingController? textEditingController;
  final IconData? iconData;
  final String? hintText;
  bool? isObsecre = true;
  bool? enabled = true;
  final TextInputType? keyBoardType;

  CustomTextFormField({
    Key? key,
    required this.textEditingController,
    required this.iconData,
    required this.hintText,
    this.isObsecre,
    this.enabled,
    required this.keyBoardType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(
          Radius.circular(10),
        ),
      ),
      padding: EdgeInsets.all(8),
      margin: EdgeInsets.all(8),
      child: TextFormField(
        // validator: (value) {
        //   if (value!.length <= 8) {
        //     return "Kurang boyy";
        //   }
        // },
        keyboardType: keyBoardType,
        enabled: enabled,
        controller: textEditingController,
        obscureText: isObsecre!,
        cursorColor: Theme.of(context).primaryColor,
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(
            iconData,
            color: Colors.cyan,
          ),
          focusColor: Theme.of(context).primaryColor,
          hintText: hintText,
        ),
      ),
    );
  }
}
