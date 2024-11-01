import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class FileView extends StatelessWidget {
  final String svgPath;
  const FileView({super.key,required this.svgPath});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(svgPath);
  }
}
