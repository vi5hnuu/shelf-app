import 'dart:convert';

class Shelf{
  final String? parentShelfId;
  final String title;
  final String description;
  final String? coverImage;
  final String id;
  final int createdAt;
  final int updatedAt;
  final int lastAccessed;

  //transient fields
  final List<Shelf> shelfs;
  final List<File> files;
  double? totalPages;

  Shelf({
      required this.id,
      this.parentShelfId,
      required this.title,
      required this.description,
      required this.coverImage,
      required this.createdAt,
      required this.updatedAt,
      required this.lastAccessed,
      List<Shelf>? shelfs,
      List<File>? files,
      this.totalPages
  }):shelfs= shelfs ?? List.empty(growable: true),files=files ?? List.empty(growable: true);

  factory Shelf.rootShelf({required String rootShelfId}){
    final now=DateTime.now().millisecondsSinceEpoch;
    return Shelf(id: rootShelfId,
        title: '',
        description: 'Root Shelf',
        coverImage: null,
        createdAt: now,
        updatedAt: now,
        lastAccessed: now);
  }

  Shelf addToShelf({required String shelfId,List<Shelf> shelfs=const [],List<File> files=const [],double? totalPages}){
    if(shelfs.isEmpty && files.isEmpty) return this;
    final Shelf? shelf=getShelf(shelfId: shelfId);
    if(shelf==null) throw Exception("Invalid shelf id");
    shelf.shelfs.addAll(shelfs);
    shelf.files.addAll(files);
    shelf.totalPages=totalPages ?? shelf.totalPages;
    return this;
  }

  Shelf copyWith({double? totalPages,
    List<Shelf>? shelfs,
    List<File>? files}){
    return Shelf(
        id: id,
        parentShelfId:parentShelfId,
        title: title,
        description: description,
        coverImage: coverImage,
        createdAt: createdAt,
        updatedAt: updatedAt,
        files: files ?? this.files,
        shelfs: shelfs ?? this.shelfs,
        totalPages: totalPages ?? this.totalPages,
        lastAccessed: lastAccessed);
  }

  Shelf? getShelf({required String shelfId,List<Shelf>? path}){//from this node to all down-wards node
    return getShelfFrom(shelf: this, shelfId: shelfId,path: path);
  }

  Shelf? getShelfFrom({required Shelf shelf,required String shelfId,List<Shelf>? path}){//return shelf if found and path if path ref is passed
    path?.add(shelf);
    if(shelf.id==shelfId) {
      return shelf;
    }

    for(final shlf in shelf.shelfs){
      if(shlf.id!=shelfId) continue;
      path?.add(shlf);
      return shlf;
    }

    for(final shlf in shelf.shelfs){
      final reqShelf=getShelfFrom(shelf: shlf, shelfId: shelfId,path: path);
      if(reqShelf!=null) return reqShelf;
    }
    path?.removeLast();
    return null;
  }

  static Shelf fromMap(Map<String, dynamic> shelfJson) {
    return Shelf(
        id: shelfJson['id'] as String,
        parentShelfId: shelfJson['parent_shelf_id'] as String?,
        title: shelfJson['title'] as String,
        description: shelfJson['description'] as String,
        coverImage: shelfJson['cover_image'] as String?,
        createdAt: shelfJson['created_at'] as int,
        updatedAt: shelfJson['updated_at'] as int,
        lastAccessed: shelfJson['last_accessed'] as int);
  }

  bool hasItems() {
    return shelfs.isNotEmpty || files.isNotEmpty;
  }
}

class File {
  final String? shelfId;
  final String filePath;
  final String title;
  final String type;
  final int size; //bytes
  final List<String> tags;
  final String description;
  final String id;
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
        required this.createdAt,
        required this.updatedAt,
        required this.lastAccessedAt,
        required this.favourite});

  static File  fromMap(Map<String, dynamic> fileJson) {
    return File(id: fileJson['id'] as String,
        shelfId: fileJson['shelf_id'] as String?,
        filePath: fileJson['file_path'] as String,
        title: fileJson['title'] as String,
        type: fileJson['type'] as String,
        size: fileJson['size'] as int,
        tags: (jsonDecode(fileJson['tags'] as String) as List).map((tag)=>tag as String).toList(),
        description: fileJson['description'] as String,
        createdAt: fileJson['created_at'] as int,
        updatedAt: fileJson['updated_at'] as int,
        lastAccessedAt: fileJson['last_accessed'] as int,
        favourite: (fileJson['favorite'] as int)==1);
  }
}

