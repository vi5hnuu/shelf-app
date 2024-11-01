
extension SetEntensions<V> on Set<V> {
  Set<V> clone(){
    return Set.from(this);
  }
}