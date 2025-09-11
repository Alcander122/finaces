// presentations/widgets/auth/login_divider.dart
import 'package:flutter/material.dart';

class LoginDivider extends StatelessWidget {
  const LoginDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Divider(
            thickness: 0.7,
            color: Colors.grey.withAlpha(50),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text('Login', style: TextStyle(color: Colors.black45)),
        ),
        Expanded(
          child: Divider(
            thickness: 0.7,
            color: Colors.grey.withAlpha(50),
          ),
        ),
      ],
    );
  }
}
