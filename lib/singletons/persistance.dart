import 'dart:async';
import 'dart:convert';

import 'package:shelf/constants/IdGenerators.dart';
import 'package:shelf/constants/constants.dart';
import 'package:shelf/models/Pageable.dart';
import 'package:shelf/models/shelf.dart';
import 'package:shelf/singletons/LoggerSingleton.dart';
import 'package:sqflite/sqflite.dart';

class Persistance{
  static Database? _db;
  static const String _dbName="shelf-DB";

  //shelf === folder but only for docs thats why shelf
  static const String _tableShelf="shelf";//SIDX{28}
  static const String _tableFile="file"; //UID -> FIDX{28}

  //shelf delete -> child shelf delete + files delete
  static const String _shelfTableCreateQuery='''
        CREATE TABLE $_tableShelf (
          id TEXT PRIMARY KEY,
          parent_shelf_id TEXT,
          title TEXT NOT NULL,
          description TEXT DEFAULT "",
          cover_image TEXT,
          tag TEXT DEFAULT "",
          active INTEGER DEFAULT 1,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          last_accessed INTEGER NOT NULL,
          FOREIGN KEY (parent_shelf_id) REFERENCES $_tableShelf(id) ON DELETE CASCADE
        )
      ''';

  //type -> PDF,DOC,INVOICE etc (most of the time === extension of file)
  //size in bytes
  static const String _fileTableCreateQuery='''
        CREATE TABLE $_tableFile (
          id TEXT PRIMARY KEY,
          shelf_id TEXT,
          file_path TEXT NOT NULL,
          title TEXT,
          type TEXT,
          size INTEGER,
          tags TEXT DEFAULT "",
          active INTEGER DEFAULT 1,
          description TEXT DEFAULT "",
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          last_accessed INTEGER NOT NULL,
          favorite INTEGER DEFAULT 0,
          FOREIGN KEY (shelf_id) REFERENCES $_tableShelf(id) ON DELETE CASCADE
        )
      ''';

  static Timer? _timer;
  static bool _initiated=false;

  static final Persistance _instance = Persistance._();

  Persistance._();

  factory Persistance(){
    return _instance;
  }

  static Future<void> initDB() async{
    try{
      if(_initiated) throw Exception("do not re-initiate persistance");
      _initiated=true;

      _timer=Timer.periodic(const Duration(seconds: 30), (timer) => _deleteOldInactiveItems());
      _db = await openDatabase(_dbName,
          singleInstance: true,
          version: 1,
          onConfigure: (db) async{
            await db.execute('PRAGMA foreign_keys = ON');
            LoggerSingleton().logger.i("Foreign key enabled");
          },
          onOpen: (db) => LoggerSingleton().logger.i("database created : ${db.path}"),
          onCreate: (db, version)  async {
            await db.execute(_shelfTableCreateQuery);
            LoggerSingleton().logger.i("Table $_tableShelf created");
            await db.execute(_fileTableCreateQuery);
            LoggerSingleton().logger.i("Table $_tableFile created");
          });
    }catch(e){
      throw Exception("Intiation failed, please try again");
    }
  }

  get db{
    return _db;
  }

  createShelf({
    String? parentShelfId,
    required String title,
    String? description="",
    String? coverImage,
    List<String>? tags=const []}) async{
    assert(_db!=null);

    String sqlShelfQuery = '''
    INSERT INTO $_tableShelf (id,parent_shelf_id,title,description,cover_image,tag,created_at,updated_at,last_accessed)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
  ''';
    final shelfId=IdGenerators.generateId(prefix: Constants.SHELF_ID_PREFIX);
    final createTime=DateTime.now().millisecondsSinceEpoch;
    await _db!.execute(sqlShelfQuery,
        [shelfId,
          parentShelfId,
          title,
          description,
          coverImage,
          jsonEncode(tags),
          createTime,
          createTime,
          createTime
        ]);
    LoggerSingleton().logger.i("Created Shelf $title : $shelfId");
  }

  createFile({
    required String? shelfId,
    required String filePath,
    required String title,
    required String type,
    required int size,
    List<String> tags=const [],
    String description='',
  }) async{
    assert(_db!=null);

    String sqlShelfQuery = '''
    INSERT INTO $_tableFile (id,shelf_id,file_path,title,type,size,tags,description,created_at,updated_at,last_accessed)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  ''';
    final String fileId=IdGenerators.generateId(prefix: Constants.SHELF_ID_PREFIX);
    final int createTime=DateTime.now().millisecondsSinceEpoch;

    await _db!.rawInsert(sqlShelfQuery, [
          fileId,
          shelfId,
          filePath,
          title,
          type,
          size,
          jsonEncode(tags).toString(),
          description,
          createTime,
          createTime,
          createTime]);
    LoggerSingleton().logger.i("Created file $title : $fileId");
  }


  Future<int> _getTotalShelfs({String? parentShelfId}) async{
    assert(_db!=null);
    final List<Map<String, dynamic>> countResult = await _db!.rawQuery(
      'SELECT COUNT(*) as total FROM $_tableShelf WHERE ${parentShelfId != null ? 'parent_shelf_id = ?' : 'parent_shelf_id IS ?'}',[parentShelfId]);
    return countResult.isNotEmpty ? countResult.first['total'] as int : 0;
  }

  Future<int> _getTotalFileInShelf({required String? shelfId}) async{
    assert(_db!=null);
    final List<Map<String, dynamic>> countResult = await _db!.rawQuery(
      'SELECT COUNT(*) as total FROM $_tableFile WHERE ${shelfId!=null ? 'shelf_id=?':'shelf_id IS ?'}',
      [shelfId]
    );
    return countResult.isNotEmpty ? countResult.first['total'] as int : 0;
  }

  Future<List<Shelf>> getShelfsFromOffset({String? parentShelfId,required int offset,required int limit}) async {
    assert(offset>=0 && limit>0 && limit<=50 && _db!=null);

    final List<Map<String, dynamic>> shelfsRaw = await _db!.query(
        _tableShelf,
        where: parentShelfId!=null ? 'parent_shelf_id = ?':'parent_shelf_id IS ?',
        whereArgs: [parentShelfId],
        limit: limit,
        offset: offset,
        orderBy: 'created_at ASC'
    );
    final List<Shelf> shelfs=shelfsRaw.map((shelf)=>Shelf.fromMap(shelf)).toList(growable: false);
    return Future.value(shelfs);
  }

  Future<List<File>> getFilesFromOffset({String? shelfId,required int offset,required int limit}) async {
    assert(offset>=0 && limit>0 && limit<=50 && _db!=null);

    final List<Map<String, dynamic>> filesRaw = await _db!.query(
        _tableFile,
        where: shelfId!=null ? 'shelf_id = $shelfId' : 'shelf_id IS NULL',
        limit: limit,
        offset: offset,
        orderBy: 'created_at ASC'
    );
    final List<File> files=filesRaw.map((file)=>File.fromMap(file)).toList(growable: false);
    return Future.value(files);
  }

  Future<int> _moveFileToShelf({required String? toShelfId,required List<String> fileIds}) async {
    assert(fileIds.isNotEmpty && _db!=null);

    const filesMoveUpdateQuery= '''
      UPDATE TABLE $_tableFile
      SET shelf_id=?
      where id in (?)
    ''';

    return await _db!.rawUpdate(filesMoveUpdateQuery,[toShelfId,fileIds.join(',')]);
  }

  Future<int> _moveShelfsToShelf({required String? toShelfId,required List<String> shelfIds}) async {
    assert(shelfIds.isNotEmpty && _db!=null);
    const filesMoveUpdateQuery= '''
      UPDATE TABLE $_tableShelf
      SET parent_shelf_id=?
      where id in (?)
    ''';
    return await _db!.rawUpdate(filesMoveUpdateQuery,[toShelfId,shelfIds.join(',')]);
  }

  Future<int> _deleteShlefs({required List<String> shelfIds,required bool permanentDelete}) async{
    if(shelfIds.isEmpty || _db==null) throw Exception("Invalid State");

    if(permanentDelete){
      return await _db!.rawDelete('''
        DELETE FROM $_tableShelf
        WHERE id IN (?);
      ''',[shelfIds.join(',')]);
    }
    return await _db!.rawUpdate('''
      UPDATE TABLE $_tableShelf
      SET active=0
      WHERE id IN (?)
    ''', [shelfIds.join(',')]);
  }

  Future<int> _deleteFiles({required List<String> fileIds,required bool permanentDelete}) async{
    if(fileIds.isEmpty || _db==null) throw Exception("Invalid State");

    if(permanentDelete){
      return await _db!.rawDelete('''
        DELETE FROM $_tableFile
        WHERE id in (?)
      ''',[fileIds.join(',')]);
    }
    return await _db!.rawUpdate('''
      UPDATE TABLE $_tableFile
      SET active=0
      WHERE id IN (?)
    ''', [fileIds.join(',')]);
  }

  static void _deleteOldInactiveItems() async {//delete inactive items older than 1 month
    return;
    if(_db==null){
      LoggerSingleton().logger.w("Db not initialized, skipping [_deleteOldInactiveItems()]");
      return;
    }
    final int oneMonthAgo = DateTime.now().subtract(const Duration(days: 30)).millisecondsSinceEpoch;

    // Query to delete items where active = false and created_at is more than 30 days old
    await _db!.rawDelete('''
      DELETE FROM $_tableFile
      WHERE active=? AND updated_at < ?
    ''',[0,oneMonthAgo]);
  }

  Future<Pageable<Shelf>> getShelfs({String? parentShelfId,int pageNo = 1, int limit = 10}) async {
    assert(pageNo>=1 && limit>10 && limit<=50 && _db!=null);
    final List<Shelf> shelfs=await getShelfsFromOffset(parentShelfId: parentShelfId,offset: (pageNo-1)*limit,limit: limit);

    //calculating total pages
    final totalPages=await _getTotalShelfs(parentShelfId: parentShelfId)/limit;
    return Future.value(Pageable<Shelf>(pageNo: pageNo,totalPages: totalPages,data: shelfs));
  }

  //both shelfs and files [we allow root to have shelfs and files]
  Future<Pageable<Object>> getItemsInShelf({required String? shelfId,int pageNo = 1, int limit = 10}) async {
    assert(pageNo>=1 && limit>10 && limit<=50 && _db!=null);
    final totalShelfs=await _getTotalShelfs(parentShelfId: shelfId);

    final totalFilesInShelf=await _getTotalFileInShelf(shelfId: shelfId);
    final totalPages=(totalShelfs+totalFilesInShelf)/limit;

    //we return shelfs first then files
    final List<Shelf> shelfs=await getShelfsFromOffset(parentShelfId: shelfId,offset: (pageNo-1)*limit, limit: limit);
    if(shelfs.length==limit){
        return Pageable<Object>(data: shelfs, pageNo: pageNo, totalPages: totalPages);
    }

    final leftItems=limit-shelfs.length;
    /*
    eg : i want 4th page and shelfs has 3.5 pages -> i want 0.5 pages of files [ offset = 0 ,fetch = 5 ]
    eg : i want 8th page and shelfs has 3.5 pages -> i want 4.5 pages of files [ offset = (4.5-1)*limit ,fetch = 10 = limit ]
    * */

    //we should not use (curItems/limit) as it can be like  2.33333 etc which gives wrong skip
    // final int skipItems=((pageNo-onlyShelfPages-1)*limit).toInt();
    final int skipItems=(pageNo*limit-totalShelfs-limit).toInt();
    final List<File> files=await getFilesFromOffset(offset: skipItems>=0 ? skipItems : 0, limit: leftItems);

    return Pageable<Object>(data: [...shelfs,...files], pageNo: pageNo, totalPages: totalPages);
  }

  Future<int> moveItemsTo({required String? toShelfId,required List<String> fileIds,required List<String> shelfIds}) async{
    assert((fileIds.isNotEmpty || shelfIds.isNotEmpty) && _db!=null);

    List<Future> futures=[];
    if(shelfIds.isNotEmpty) futures.add(_moveShelfsToShelf(toShelfId: toShelfId, shelfIds: shelfIds));
    if(fileIds.isNotEmpty) futures.add(_moveFileToShelf(toShelfId: toShelfId, fileIds: fileIds));
    final result=await Future.wait(futures);
    return result.reduce((value, element) => value+element);
  }

  Future<int> deleteItems({required List<String> fileIds,required List<String> shelfIds,required bool permanentDelete}) async{
    if((shelfIds.isEmpty && fileIds.isEmpty) || _db==null) throw Exception("Invalid state");

    List<Future> futures=[];

    if(fileIds.isNotEmpty) futures.add(_deleteFiles(fileIds: fileIds, permanentDelete: permanentDelete));
    if(shelfIds.isNotEmpty) futures.add(_deleteShlefs(shelfIds: shelfIds, permanentDelete: permanentDelete));
    final result=await Future.wait(futures);
    return result.reduce((value, element) => value+element);
  }

  void dispose()async{
    await _db?.close();
    _timer?.cancel();
  }

  void createDummyData(int from,int maxLevel,String? psid)async {
    if(from==maxLevel) return;
    for(int i=0;i< 10;i++){//last 10 shelf has only 10 files [make understand in video]
      final String shelfId=IdGenerators.generateId(prefix: Constants.SHELF_ID_PREFIX);
      final String fileId=IdGenerators.generateId(prefix: Constants.SHELF_ID_PREFIX);
      _dummyShelf(shelfId,psid);
      _dummyFile(fileId,psid);
      createDummyData(from+1, maxLevel,shelfId);
    }
  }

  _dummyShelf(String sid,String? pid)async{
    String sqlShelfQuery = '''
    INSERT INTO $_tableShelf (id,parent_shelf_id,title,description,cover_image,tag,created_at,updated_at,last_accessed)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
  ''';
    final createTime=DateTime.now().millisecondsSinceEpoch;
    await _db!.execute(sqlShelfQuery,
    [sid,
      pid,
    'shelf-title-$sid',
    'shelf-description-$sid}',
    null,
    jsonEncode(['tags-$sid']).toString(),
    createTime,
    createTime,
    createTime
    ]);
    LoggerSingleton().logger.i("Created Shelf -$sid");
  }
  _dummyFile(String fid,String? sid) async{
    String sqlShelfQuery = '''
    INSERT INTO $_tableFile (id,shelf_id,file_path,title,type,size,tags,description,created_at,updated_at,last_accessed)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  ''';
    final int createTime=DateTime.now().millisecondsSinceEpoch;

    await _db!.rawInsert(sqlShelfQuery, [
    fid,
    sid,
    'filePath',
    'title-$fid',
    'pdf',
    10,
    jsonEncode(['tags-$fid']).toString(),
    'description-$fid',
    createTime,
    createTime,
    createTime]);
    LoggerSingleton().logger.i("Created file -$fid");
  }
}