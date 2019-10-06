import 'dart:typed_data';

import 'mm_file_manager.dart';
import 'mm_persisted_storage.dart';

typedef Future<Uint8List> MMFileDownloader(String uuid, String url);
typedef Future<Uint8List> MMFileProcessor(String url, String processType);

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

  getFile(String uuid, String url, String fileType, String processType, MMFileProcessor processor) async {
    assert(storage != null, "pls setup");
    assert(download != null, "pls setup");

    var fileObject = await storage.queryRecord(uuid);
    if (fileObject == null) {
      fileObject = await storage.createRecord(uuid, url, fileType, processType);
    }

    if (!fileObject.download || fileObject.dirty) {
      final fileBytes = await download(uuid, url);
      // Save file
      final file = await MMFileManager.save(fileBytes, uuid, fileType);

      fileObject.localURL = file.path.toString();
      fileObject.download = true;
      fileObject.dirty = false;
      fileObject.processed = false;
      storage.setDownloaded(uuid, fileObject.localURL);
    }

    if (!fileObject.processed) {
      final fileBytes = await processor(url, processType);
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