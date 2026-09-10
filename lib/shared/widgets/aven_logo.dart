import 'package:flutter/material.dart';

class AvenLogo extends StatelessWidget {
  final double size;

  const AvenLogo({
    super.key, 
    this.size = 96,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/images/logo_new.png',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}
