import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:food_online_shop/widgets/progress_bar.dart';

class LoadingDialog extends StatelessWidget {
  final String? message;

  LoadingDialog({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: key,
      content: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          circularProgress(),
          SizedBox(
            height: 10,
          ),
          Text(message! + "Please wait . . .")
        ],
      ),
    );
  }
}
