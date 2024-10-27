import 'package:uuid/uuid.dart';

class IdGenerators {
  static const _uuid=Uuid();

  static  generateId({String prefix=''}){//32 chars
    if(prefix.length>=5) throw Exception("prefix length must be less then 5");

    String uniqueId = prefix+_uuid.v4().replaceAll('-', '');
    return  (uniqueId).substring(0,32);
  }
}
