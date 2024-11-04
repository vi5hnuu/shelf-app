import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ItemView extends StatelessWidget {
  final String svgPath;
  final bool selectable;
  final bool selected;
  final String? title;
  final void Function(bool?)? onSelect;

  const ItemView({super.key,required this.svgPath,this.title,this.selectable=false,this.onSelect,this.selected=false});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Column(
          children: [
            Flexible(child: SvgPicture.asset(svgPath,fit: BoxFit.contain,)),
            if(title!=null) Text(title!,maxLines: 1,overflow: TextOverflow.ellipsis,style: TextStyle(color: Colors.black))
          ],
        ),
        if(selectable) Positioned(top: -15,right: -15, child: Checkbox(tristate: false,value: selected, onChanged: onSelect,)),
      ],
    );
  }
}
