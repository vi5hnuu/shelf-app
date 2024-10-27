import 'dart:convert';


class Shelf {
  final String id;
  final String? parentShelfId;
  final String title;
  final String description;
  final String? coverImage;
  final bool active;
  final int createdAt;
  final int updatedAt;
  final int lastAccessed;

  //transient field
  final List<Object> items=[];

  Shelf(
      {required this.id,
      this.parentShelfId,
      required this.title,
      required this.description,
      required this.coverImage,
      required this.active,
      required this.createdAt,
      required this.updatedAt,
      required this.lastAccessed});

  static Shelf fromMap(Map<String, dynamic> shelfJson) {
    return Shelf(
        id: shelfJson['id'] as String,
        parentShelfId: shelfJson['parent_shelf_id'] as String?,
        title: shelfJson['title'] as String,
        description: shelfJson['description'] as String,
        coverImage: shelfJson['cover_image'] as String?,
        active: (shelfJson['active'] as int)==1,
        createdAt: shelfJson['created_at'] as int,
        updatedAt: shelfJson['updated_at'] as int,
        lastAccessed: shelfJson['last_accessed'] as int);
  }
}

class File {
  final String id;
  final String shelfId;
  final String filePath;
  final String title;
  final String type;
  final int size; //bytes
  final List<String> tags;
  final bool active;
  final String description;
  final int createdAt;
  final int updatedAt;
  final int lastAccessedAt;
  final bool favourite;

  File(
      {required this.id,
        required this.shelfId,
        required this.filePath,
        required this.title,
        required this.type,
        required this.size,
        required this.tags,
        required this.active,
        required this.description,
        required this.createdAt,
        required this.updatedAt,
        required this.lastAccessedAt,
        required this.favourite});

  static File  fromMap(Map<String, dynamic> fileJson) {
    return File(id: fileJson['id'] as String,
        shelfId: fileJson['shelf_id'] as String,
        filePath: fileJson['file_path'] as String,
        title: fileJson['title'] as String,
        type: fileJson['type'] as String,
        size: fileJson['size'] as int,
        tags: (jsonDecode(fileJson['tags'] as String) as List).map((tag)=>tag as String).toList(),
        active: (fileJson['active'] as int)==1,
        description: fileJson['description'] as String,
        createdAt: fileJson['created_at'] as int,
        updatedAt: fileJson['updated_at'] as int,
        lastAccessedAt: fileJson['last_accessed_at'] as int,
        favourite: (fileJson['favourite'] as int)==1);
  }
}

