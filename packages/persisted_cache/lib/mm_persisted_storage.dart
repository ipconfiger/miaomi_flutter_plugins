
import 'mm_file_info.dart';

abstract class MMPersistedStorage {
	Future<MMFileInfo> queryRecord(String uuid) ;
	Future<MMFileInfo> createRecord(MMFileInfo fileInfo);
	Future setDownloaded(String uuid, String localURL);
	Future setProcessed(String uuid, String thumbnailURL);
 	Future setDirty(String uuid);
}
