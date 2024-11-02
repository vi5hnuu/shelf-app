import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ShelfView extends StatelessWidget {
  final String svgPath;
  final String? title;

  const ShelfView({super.key,required this.svgPath,this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Flexible(child: SvgPicture.asset(svgPath,fit: BoxFit.contain,)),
        if(title!=null) Text(title!,maxLines: 1,overflow: TextOverflow.ellipsis,style: TextStyle(color: Colors.black))
      ],
    );
  }
}
