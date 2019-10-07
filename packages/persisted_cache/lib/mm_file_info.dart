library persisted_cache;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

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

	String basePath;
	 getThumbFullRUL() async {
		return p.join(basePath, "$thumbnailURL");
	}

	getLocalFullURL() async {
		return p.join(basePath, "$localURL");
	}
}
