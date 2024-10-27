class AartiInfoModel {
  final String id;
  final String title;

  const AartiInfoModel({
    required this.id,
    required this.title,
  });

  factory AartiInfoModel.fromJson(Map<String, dynamic> json) {
    return AartiInfoModel(
      id: json['id'],
      title: json['title'],
    );
  }
}
