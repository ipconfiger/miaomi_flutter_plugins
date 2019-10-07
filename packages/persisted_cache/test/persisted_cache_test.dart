import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:persisted_cache/persisted_cache.dart';

class MMTestStorage extends MMPersistedStorage {

  @override
  Future<MMFileInfo> queryRecord(String uuid) {
    return null;
  }

  @override
  Future setDirty(String uuid) {
    return null;
  }

  @override
  Future setDownloaded(String uuid, String localURL) {
    return null;
  }

  @override
  Future setProcessed(String uuid, String thumbnailURL) {
    return null;
  }

  @override
  Future<MMFileInfo> createRecord(MMFileInfo fileInfo) {
    return null;
  }

}

void main() {
  test('adds one to input values', () {
    Future<Uint8List> _fileDownloader(MMFileInfo fileInfo) async {
      return Uint8List(0);
    }

    Future<Uint8List> _fileProcessor(MMFileInfo fileInfo) async {
      return Uint8List(0);
    }

    final persistedCache = PersistedCache();
    persistedCache.setup(MMTestStorage(), _fileDownloader);

    persistedCache.getFile("0000", "img", "url", "avartaImage", _fileProcessor);
//    expect(calculator.addOne(2), 3);
//    expect(calculator.addOne(-7), -6);
//    expect(calculator.addOne(0), 1);
//    expect(() => calculator.addOne(null), throwsNoSuchMethodError);
  });
}
