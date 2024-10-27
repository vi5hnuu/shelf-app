class  Pageable<T> {
    final List<T> data;
    final int pageNo;
    final double totalPages;

    Pageable({required this.data, required this.pageNo, required this.totalPages});

    Pageable<T> copyWith({List<T>? data, int? pageNo, double? totalPages}){
        return Pageable<T>(data: data ?? this.data, pageNo: pageNo ?? this.pageNo, totalPages: totalPages ?? this.totalPages);
    }
}