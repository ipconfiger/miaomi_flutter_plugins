library persisted_cache;

import 'package:path/path.dart' as p;

/// A Calculator.
class MMFileInfo {
  String uuid;
  String originalURL;
  String localURL;
  String thumbnailURL;
  String fileType;
  String processType;
  bool download;
  bool processed;
  bool dirty;

  String basePath;

  getThumbFullRUL() {
    return p.join(basePath, "$thumbnailURL");
  }

  getLocalFullURL() {
    return p.join(basePath, "$localURL");
  }
}
