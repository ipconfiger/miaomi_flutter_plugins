import 'dart:typed_data';

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

  Stream<MMFileInfo> getFileStream(String uuid, String url, String fileType, String processType, MMFileProcessor processor) async* {
    try {
      var webFile = await getFile(uuid, url, fileType, processType, processor);
      if (webFile != null) {
        yield webFile;
      }
    } catch (e) {
      print(e);
      throw e;
    }
  }

  Future<MMFileInfo> getFile(String uuid, String url, String fileType, String processType, MMFileProcessor processor) async {
    assert(storage != null, "pls setup");
    assert(download != null, "pls setup");

    var fileObject = await storage.queryRecord(uuid);
    if (fileObject == null) {
      MMFileInfo fileInfo = MMFileInfo();
      fileInfo.uuid = uuid;
      fileInfo.originalURL = url;
      fileInfo.fileType = fileType;
      fileInfo.processType = processType;
      fileObject = await storage.createRecord(fileInfo);
    }
    fileObject.basePath = _filePath;

    if (!fileObject.download || fileObject.dirty) {
      final fileBytes = await download(fileObject);
      // Save file
      final file = await MMFileManager.save(fileBytes, uuid, fileType);

      fileObject.localURL = "$fileType/$uuid";
      fileObject.download = true;
      fileObject.dirty = false;
      fileObject.processed = false;
      storage.setDownloaded(uuid, fileObject.localURL);
    }

    if (!fileObject.processed) {
      final fileBytes = await processor(fileObject);
      // Save file
      await MMFileManager.save(fileBytes, "${uuid}_thumb", fileType);
      fileObject.thumbnailURL = "$fileType/${uuid}_thumb";
      fileObject.processed = true;
      storage.setProcessed(uuid, fileObject.thumbnailURL);
    }
    return fileObject;
  }

  markDirty(String uuid, String originalURL) async {
    await storage.setDirty(uuid, originalURL);
  }
}
