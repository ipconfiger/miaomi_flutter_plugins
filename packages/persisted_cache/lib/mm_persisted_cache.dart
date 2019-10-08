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
    var catchID = PersistedCache.catchID(uuid, fileType);
    print("PersistedCache=== catchID:$catchID");
    var fileObject = await storage.queryRecord(catchID);
    if (fileObject == null) {
      print("PersistedCache=== fileObject null");
      MMFileInfo fileInfo = MMFileInfo();
      fileInfo.uuid = catchID;
      fileInfo.originalURL = url;
      fileInfo.fileType = fileType;
      fileObject = await storage.createRecord(fileInfo);
    } else {
      print("PersistedCache=== fileObject not null");
    }


    fileObject.basePath = _filePath;

    print("PersistedCache=== pre download ${fileObject.toString()}");

    if (!fileObject.download || fileObject.dirty) {
      final fileBytes = await download(fileObject);
      // Save file
      final file = await MMFileManager.save(fileBytes, catchID, fileType);
      fileObject.originalURL = url;
      fileObject.localURL = "$fileType/$catchID";
      fileObject.download = true;
      fileObject.dirty = false;
      fileObject.processed = false;
      await storage.setDownloaded(catchID, fileObject.localURL);
    }

    print("PersistedCache=== pre processed ${fileObject.toString()}");
    if (!fileObject.processed) {
      final fileBytes = await processor(fileObject);
      // Save file
      await MMFileManager.save(fileBytes, "${catchID}_thumb", fileType);
      fileObject.thumbnailURL = "$fileType/${catchID}_thumb";
      fileObject.processed = true;
      await storage.setProcessed(catchID, fileObject.thumbnailURL);
    }
    print("PersistedCache=== result ${fileObject.toString()}");

    return fileObject;
  }


  Future<MMFileInfo> updateFile(String uuid, String url, String fileType, MMFileProcessor processor, Uint8List localFileBytes) async {
    var catchID = PersistedCache.catchID(uuid, fileType);
    print("PersistedCache=== updateFile getFile:$uuid $url $fileType");
    print("PersistedCache=== updateFile catchID:$catchID");

    var fileObject = await storage.queryRecord(catchID);
    if (fileObject == null) {
      print("PersistedCache=== fileObject null");

      MMFileInfo fileInfo = MMFileInfo();
      fileInfo.uuid = catchID;
      fileInfo.originalURL = url;
      fileInfo.fileType = fileType;
      fileObject = await storage.createRecord(fileInfo);
    } else {
      print("PersistedCache=== fileObject not null");
    }

    await storage.updateURL(catchID, url);

    fileObject.basePath = _filePath;
    print("PersistedCache=== updateFile pre download ${fileObject.toString()}");

    // Save filenashi
    final file = await MMFileManager.save(localFileBytes, catchID, fileType);
    fileObject.originalURL = url;
    fileObject.localURL = "$fileType/$catchID";
    fileObject.download = true;
    fileObject.dirty = false;
    fileObject.processed = false;
    await storage.setDownloaded(catchID, fileObject.localURL);

    print("PersistedCache=== updateFile pre processed ${fileObject.toString()}");

    final fileBytes = await processor(fileObject);
    // Save file
    await MMFileManager.save(fileBytes, "${catchID}_thumb", fileType);
    fileObject.thumbnailURL = "$fileType/${catchID}_thumb";
    fileObject.processed = true;
    await storage.setProcessed(catchID, fileObject.thumbnailURL);
    print("PersistedCache=== updateFile result ${fileObject.toString()}");

    return fileObject;
  }


  static catchID(String uuid, String fileType) {
    return '${uuid}_${fileType}';
  }

  markDirty(String uuid, String fileType) async {
    await markDirtyBy(PersistedCache.catchID(uuid, fileType));
  }

  markDirtyBy(String catchID) async {
    await storage.setDirty(catchID);
  }
}
