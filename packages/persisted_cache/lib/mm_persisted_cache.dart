import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:persisted_cache/mm_file_info.dart';

import 'mm_file_manager.dart';
import 'mm_persisted_storage.dart';

typedef Future<Uint8List> MMFileDownloader(MMFileInfo fileInfo);
typedef Future<Uint8List> MMFileProcessor(MMFileInfo fileInfo);

typedef MMFileLoadCallback(MMFileInfo fileInfo, MMFileInfoStatus status);

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

  String fullURL(String path) {
    return p.join(_filePath, path);
  }

//  Stream<MMFileInfo> getFileStream(String uuid, String url, String fileType, MMFileProcessor processor) async* {
//    try {
//      var webFile = await getFile(uuid, url, fileType, processor);
//      if (webFile != null) {
//        yield webFile;
//      }
//    } catch (e) {
//      print(e);
//      throw e;
//    }
//  }
//

//
//  Future<MMFileInfo> getFile(String uuid, String url, String fileType, MMFileProcessor processor) async {
//    var fileObject = await storage.queryRecord(uuid);
//    if (fileObject == null) {
//      MMFileInfo fileInfo = MMFileInfo();
//      fileInfo.uuid = uuid;
//      fileInfo.originalURL = url;
//      fileInfo.fileType = fileType;
//      fileInfo.download = false;
//      fileInfo.processed = false;
//      fileObject = await storage.createRecord(fileInfo);
//    }
//
//    if (fileObject.originalURL != url) {
//      await storage.updateURL(uuid, url);
//      fileObject.originalURL = url;
//    }
//
//    fileObject.basePath = _filePath;
//
//    if (!fileObject.download || fileObject.dirty) {
//      final fileBytes = await download(fileObject);
//      print("Download URL ${fileObject.originalURL}");
//
//      final fileExt = url.split('.').last.split("#").first;
//      // Save file
//      final fileName = "$uuid.$fileExt";
//      await MMFileManager.save(fileBytes, fileName, fileType);
//      fileObject.localURL = "$fileType/$fileName";
//      fileObject.download = true;
//      fileObject.dirty = false;
//      fileObject.processed = false;
//      await storage.setDownloaded(uuid, fileObject.localURL);
//    }
//
//    if (!fileObject.processed) {
//      final fileBytes = await processor(fileObject);
//      // Save file
//      if (fileBytes.isNotEmpty) {
//        await MMFileManager.save(fileBytes, "${uuid}_thumb", fileType);
//        fileObject.thumbnailURL = "$fileType/${uuid}_thumb";
//      } else {
//        fileObject.thumbnailURL = "";
//      }
//      fileObject.processed = true;
//      await storage.setProcessed(uuid, fileObject.thumbnailURL);
//    }
//
//    return fileObject;
//  }

  Future loadFile(String uuid, String url, String fileType, MMFileProcessor processor, MMFileLoadCallback callback) async {
    var fileObject = await storage.queryRecord(uuid);
    if (fileObject == null) {
      MMFileInfo fileInfo = MMFileInfo();
      fileInfo.uuid = uuid;
      fileInfo.originalURL = url;
      fileInfo.fileType = fileType;
      fileInfo.download = false;
      fileInfo.processed = false;
      fileObject = await storage.createRecord(fileInfo);
      callback(fileObject, MMFileInfoStatus.create);
    } else {
      await storage.updateURL(uuid, url);
      fileObject.originalURL = url;
    }


    fileObject.basePath = _filePath;

    if (!fileObject.download || fileObject.dirty) {
      final fileBytes = await download(fileObject);
      final fileExt = url.split('.').last.split("#").first;
      // Save file
      final fileName = "$uuid.$fileExt";
      await MMFileManager.save(fileBytes, fileName, fileType);
      fileObject.localURL = "$fileType/$fileName";
      fileObject.download = true;
      fileObject.dirty = false;
      fileObject.processed = false;
      await storage.setDownloaded(uuid, fileObject.localURL);
      callback(fileObject, MMFileInfoStatus.download);
    }

    if (!fileObject.processed) {
      final fileBytes = await processor(fileObject);
      // Save file
      if (fileBytes.isNotEmpty) {
        await MMFileManager.save(fileBytes, "${uuid}_thumb", fileType);
        fileObject.thumbnailURL = "$fileType/${uuid}_thumb";
      } else {
        fileObject.thumbnailURL = "";
      }

      fileObject.processed = true;
      await storage.setProcessed(uuid, fileObject.thumbnailURL);
      callback(fileObject, MMFileInfoStatus.process);
    }

    callback(fileObject, MMFileInfoStatus.finish);

    return fileObject;
  }

  Future<MMFileInfo> putFile(String uuid, String ext, String proceeType, MMFileProcessor processor, Uint8List localFileBytes) async {
    var fileObject = await storage.queryRecord(uuid);
    if (fileObject == null) {
      MMFileInfo fileInfo = MMFileInfo();
      fileInfo.uuid = uuid;
      fileInfo.originalURL = '';
      fileInfo.fileType = proceeType;
      fileInfo.download = false;
      fileInfo.processed = false;
      fileObject = await storage.createRecord(fileInfo);
    }
    fileObject.basePath = _filePath;

    // Save file
    final fileName = "$uuid.${ext.toLowerCase()}";
    await MMFileManager.save(localFileBytes, fileName, proceeType);
    fileObject.localURL = "$proceeType/$fileName";
    await storage.setDownloaded(uuid, fileObject.localURL);

    final fileBytes = await processor(fileObject);
    // Save file
    await MMFileManager.save(fileBytes, "${uuid}_thumb", proceeType);
    fileObject.thumbnailURL = "$proceeType/${uuid}_thumb";
    fileObject.processed = true;
    await storage.setProcessed(uuid, fileObject.thumbnailURL);

    return fileObject;
  }

  getCatchID(String uuid, String fileType) => '${uuid}_$fileType';

  markDirtyBy(String catchID) async {
    await storage.setDirty(catchID);
  }
}
