import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:persisted_cache/persisted_cache.dart';

class MMTestStorage extends MMPersistedStorage {
  @override
  Future<MMFileInfo> createRecord(String uuid, String originalURL, String fileType, String processType) {
    return null;
  }

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

}

void main() {
  test('adds one to input values', () {
    Future<Uint8List> _fileDownloader(String uuid, String url) async {
      return Uint8List(0);
    }

    Future<Uint8List> _fileProcessor(String url, String processType) async {
      return Uint8List(0);
    }

    final calculator = PersistedCache(MMTestStorage());

    calculator.getFile("0000", "img", "url", "avartaImage", _fileDownloader, _fileProcessor);
//    expect(calculator.addOne(2), 3);
//    expect(calculator.addOne(-7), -6);
//    expect(calculator.addOne(0), 1);
//    expect(() => calculator.addOne(null), throwsNoSuchMethodError);
  });
}
