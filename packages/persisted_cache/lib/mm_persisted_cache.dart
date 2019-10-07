import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
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

  PersistedCache._internal();

  MMPersistedStorage storage;
  MMFileDownloader download;

  setup(MMPersistedStorage storage, MMFileDownloader download) {
    this.storage = storage;
    this.download = download;
  }

  Stream<MMFileInfo> getFileStream(String uuid, String url, String fileType, String processType, MMFileProcessor processor) async* {
    try {
      var webFile = await getFile(uuid, url, fileType, processType, processor);
      if (webFile != null) {
        yield webFile;
      }
    } catch (e) {
      debugPrint("EROORO:");
      debugPrint(e);
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
      fileInfo.localURL = url;
      fileInfo.fileType = fileType;
      fileInfo.processType = processType;
      fileObject = await storage.createRecord(fileInfo);
    }

    if (!fileObject.download || fileObject.dirty) {
      final fileBytes = await download(fileObject);
      // Save file
      final file = await MMFileManager.save(fileBytes, uuid, fileType);

      fileObject.localURL = file.path.toString();
      fileObject.download = true;
      fileObject.dirty = false;
      fileObject.processed = false;
      storage.setDownloaded(uuid, fileObject.localURL);
    }

    if (!fileObject.processed) {
      final fileBytes = await processor(fileObject);
      // Save file
      final file = await MMFileManager.save(fileBytes, "${uuid}_thumb", fileType);
      fileObject.thumbnailURL = file.path.toString();
      fileObject.processed = true;
      storage.setProcessed(uuid, fileObject.thumbnailURL);
    }

    return fileObject;
  }

  markDirty(String uuid) async {
    await storage.setDirty(uuid);
  }
}
