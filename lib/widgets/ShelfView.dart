import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Shelfview extends StatelessWidget {
  final String svgPath;
  const Shelfview({super.key,required this.svgPath});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(svgPath);
  }
}
