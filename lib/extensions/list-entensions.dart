
extension ListUtils<T extends List> on List<T> {
  List<T> flat(){
    List<T> flatList=[];
    _flat(this, flatList);
    return flatList;
  }

  _flat(List<T> lst,List<T> flatList){
    if(lst.isEmpty) return;
    if(lst.first is! List<T>){
      flatList.addAll(lst);
      return;
    }
    for (var item in lst) {
      flatList.addAll(item as List<T>);
    }
    _flat([...flatList], flatList..clear());
  }
}