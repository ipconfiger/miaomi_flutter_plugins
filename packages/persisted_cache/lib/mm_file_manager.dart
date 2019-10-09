import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class MMFileManager {
  static const key = "cache";

  static Future<File> save(Uint8List fileBytes, String fileName, String fileType) async {
    var basePath = await getFilePath();
    var path = p.join(basePath, "$fileType/$fileName");
    var folder = new File(path).parent;
    if (!(await folder.exists())) {
      folder.createSync(recursive: true);
    }
    return await File(path).writeAsBytes(fileBytes);;
  }

  static Future<String> getFilePath() async {
    var directory = await getApplicationDocumentsDirectory();
    return p.join(directory.path, key);
  }


}
