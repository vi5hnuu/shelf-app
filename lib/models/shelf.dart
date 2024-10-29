import 'dart:convert';

class Shelf{
  final String? parentShelfId;
  final String title;
  final String description;
  final String? coverImage;
  final String id;
  final bool active;
  final int createdAt;
  final int updatedAt;
  final int lastAccessed;

  //transient fields
  final List<Shelf> shelfs;
  final List<File> files;
  final double? totalPages;

  Shelf({
      required this.id,
      this.parentShelfId,
      required this.title,
      required this.description,
      required this.coverImage,
      required this.active,
      required this.createdAt,
      required this.updatedAt,
      required this.lastAccessed,
      this.shelfs=const [],
      this.files=const [],
      this.totalPages
  });

  factory Shelf.rootShelf(){
    final now=DateTime.now().millisecondsSinceEpoch;
    return Shelf(id: '0',
        title: 'root',
        description: 'non-existant shelf',
        coverImage: null,
        active: true,
        createdAt: now,
        updatedAt: now,
        lastAccessed: now);
  }

  Shelf addToShelf({required String shelfId,List<Shelf> shelfs=const [],List<File> files=const []}){
    if(shelfs.isEmpty && files.isEmpty) throw Exception("both shelfs and files cannot be empty");
    final Shelf? shelf=getShelf(shelfId: shelfId);
    if(shelf==null) throw Exception("Invalid shelf id");
    shelf.shelfs.addAll(shelfs);
    shelf.files.addAll(files);
    return this;
  }

  Shelf? getShelf({required String shelfId}){//from this node to all down-wards node
    return _containShelf(shelf: this, shelfId: shelfId);
  }

  Shelf? _containShelf({required Shelf shelf,required String shelfId}){
    if(shelf.id==shelfId) return shelf;
    for(final shlf in shelf.shelfs){
      if(shlf.id==shelfId) return shelf;
    }
    for(final shlf in shelf.shelfs){
      final reqShelf=_containShelf(shelf: shlf, shelfId: shelfId);
      if(reqShelf!=null) return shelf;
    }
    return null;
  }

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
  final String shelfId;
  final String filePath;
  final String title;
  final String type;
  final int size; //bytes
  final List<String> tags;
  final String description;
  final String id;
  final bool active;
  final int createdAt;
  final int updatedAt;
  final int lastAccessedAt;
  final bool favourite;

  File({required this.id,
        required this.shelfId,
        required this.filePath,
        required this.title,
        required this.type,
        required this.size,
        required this.tags,
        required this.description,
        required this.active,
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

