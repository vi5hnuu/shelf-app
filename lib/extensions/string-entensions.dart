
extension StringUtils on String {
  String capitalize(){
    if(isEmpty) return this;
    return split(" ").map((word)=>word.isEmpty ? word : word[0].toUpperCase()+word.substring(1)).join(" ");
  }
}