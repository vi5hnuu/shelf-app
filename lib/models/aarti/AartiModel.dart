class AartiModel {
  final String id;
  final String title;
  final List<List<String>> verses;

  const AartiModel({
    required this.id,
    required this.title,
    required this.verses,
  });

  factory AartiModel.fromJson(Map<String, dynamic> json) {
    return AartiModel(
      id: json['id'],
      title: json['title'],
      verses: List<List<String>>.from(json['verses'].map((verses) => List<String>.from(verses.map((verse) => verse)))),
    );
  }
}
