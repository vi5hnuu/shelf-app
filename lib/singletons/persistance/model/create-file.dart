class CreateFile {
  final String? shelfId;
  final String filePath;
  final String title;
  final String type;
  final int size;
  final List<String> tags;
  final String description;

  const CreateFile({
    required this.shelfId,
    required this.filePath,
    required this.title,
    required this.type,
    required this.size,
    this.tags = const [],
    this.description = '',
  });
}
