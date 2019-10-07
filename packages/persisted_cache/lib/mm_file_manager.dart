import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class MMFileManager {
  static const key = "cache";

  static Future<File> save(Uint8List fileBytes, String fileName, String fileType) async {
    var filePath = await getFile("$fileType/$fileName");
    var folder = new File(filePath).parent;
    if (!(await folder.exists())) {
      folder.createSync(recursive: true);
    }
    var file = await new File(filePath).writeAsBytes(fileBytes);
    return file;
  }

  static Future<String> getFilePath() async {
    var directory = await getApplicationDocumentsDirectory();
    return p.join(directory.path, key);
  }

  static Future<String> getFile(String fileName) async {
    var basePath = await getFilePath();
    var path = p.join(basePath, "$fileName");
    return path;
  }
}
