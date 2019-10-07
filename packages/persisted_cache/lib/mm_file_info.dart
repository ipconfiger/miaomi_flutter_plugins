library persisted_cache;
import 'dart:io';

import 'mm_file_manager.dart';

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

	Future<File> getThumbFile() async {
		final filePath = await MMFileManager.getFile(thumbnailURL);
		return File(filePath);
	}

	Future<File> getLocalFile() async {
		final filePath = await MMFileManager.getFile(localURL);
		return File(filePath);
	}
}
