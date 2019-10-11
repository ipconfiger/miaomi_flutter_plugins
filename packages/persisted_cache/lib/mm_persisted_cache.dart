import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:persisted_cache/mm_file_info.dart';

import 'mm_file_manager.dart';
import 'mm_persisted_storage.dart';


typedef Future<Uint8List> MMFileDownloader(MMFileInfo fileInfo);
typedef Future<Uint8List> MMFileProcessor(MMFileInfo fileInfo);

/// A Calculator.
class PersistedCache {
  static final PersistedCache _singleton = new PersistedCache._internal();

  factory PersistedCache() {
    return _singleton;
  }

  String _filePath;

  PersistedCache._internal();

  MMPersistedStorage storage;
  MMFileDownloader download;

  setup(MMPersistedStorage storage, MMFileDownloader download) async {
    this.storage = storage;
    this.download = download;
    _filePath = await MMFileManager.getFilePath();
  }

  Stream<MMFileInfo> getFileStream(String uuid, String url, String fileType, MMFileProcessor processor) async* {
    try {
      var webFile = await getFile(uuid, url, fileType, processor);
      if (webFile != null) {
        yield webFile;
      }
    } catch (e) {
      print(e);
      throw e;
    }
  }

  String fullURL(String path) {
    return p.join(_filePath, path);
  }


  Future<MMFileInfo> getFile(String uuid, String url, String fileType, MMFileProcessor processor) async {
    assert(storage != null, "pls setup");
    assert(download != null, "pls setup");
    print("PersistedCache=== getFile:$uuid $url $fileType");
    print("PersistedCache=== catchID:$uuid");
    final fileExt = url.split('.').last.split("#").first;
    var fileObject = await storage.queryRecord(uuid);
    if (fileObject == null) {
      print("PersistedCache=== fileObject null");
      MMFileInfo fileInfo = MMFileInfo();
      fileInfo.uuid = uuid;
      fileInfo.originalURL = url;
      fileInfo.fileType = fileType;
      fileInfo.download = false;
      fileInfo.processed = false;
      fileObject = await storage.createRecord(fileInfo);
    } else {
      print("PersistedCache=== fileObject not null");
    }


    fileObject.basePath = _filePath;

    print("PersistedCache=== pre download ${fileObject.toString()}");

    if (!fileObject.download || fileObject.dirty) {
      final fileBytes = await download(fileObject);
      // Save file
      final file = await MMFileManager.save(fileBytes, "$uuid.$fileExt", fileType);
      fileObject.originalURL = url;
      fileObject.localURL = "$fileType/$uuid.$fileExt";
      fileObject.download = true;
      fileObject.dirty = false;
      fileObject.processed = false;
      await storage.setDownloaded(uuid, fileObject.localURL);
    }

    print("PersistedCache=== pre processed ${fileObject.toString()}");
    if (!fileObject.processed) {
      final fileBytes = await processor(fileObject);
      // Save file
      await MMFileManager.save(fileBytes, "${uuid}_thumb", fileType);
      fileObject.thumbnailURL = "$fileType/${uuid}_thumb";
      fileObject.processed = true;
      await storage.setProcessed(uuid, fileObject.thumbnailURL);
    }
    print("PersistedCache=== result ${fileObject.toString()}");

    return fileObject;
  }

//  var catchID = PersistedCache.catchID(uuid, fileType);

  Future<MMFileInfo> putFile(String uuid, String ext, String proceeType, MMFileProcessor processor, Uint8List localFileBytes) async {
    print("PersistedCache=== updateFile getFile:$uuid $ext $proceeType");
    print("PersistedCache=== updateFile catchID:$uuid");

    var fileObject = await storage.queryRecord(uuid);
    if (fileObject == null) {
      print("PersistedCache=== fileObject null");

      MMFileInfo fileInfo = MMFileInfo();
      fileInfo.uuid = uuid;
      fileInfo.originalURL = '';
      fileInfo.fileType = proceeType;
      fileInfo.download = false;
      fileInfo.processed = false;
      fileObject = await storage.createRecord(fileInfo);
    }
    fileObject.basePath = _filePath;


    print("PersistedCache=== updateFile pre download ${fileObject.toString()}");

    // Save filenashi
    await MMFileManager.save(localFileBytes, "$uuid.$ext", proceeType);
    fileObject.localURL = "$proceeType/$uuid.$ext";
    await storage.setDownloaded(uuid, fileObject.localURL);

    print("PersistedCache=== updateFile pre processed ${fileObject.toString()}");

    final fileBytes = await processor(fileObject);
    // Save file
    await MMFileManager.save(fileBytes, "${uuid}_thumb", proceeType);
    fileObject.thumbnailURL = "$proceeType/${uuid}_thumb";
    fileObject.processed = true;
    await storage.setProcessed(uuid, fileObject.thumbnailURL);
    print("PersistedCache=== updateFile result ${fileObject.toString()}");

    return fileObject;
  }


  getCatchID(String uuid, String fileType) => '${uuid}_${fileType}';


  markDirtyBy(String catchID) async {
    await storage.setDirty(catchID);
  }
}
