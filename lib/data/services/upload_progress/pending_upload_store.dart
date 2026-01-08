import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pending_upload_record.dart';

class PendingUploadStore {
  static const _prefsKey = 'pending_uploads_v1';

  Future<List<PendingUploadRecord>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((e) => PendingUploadRecord.fromJson(e.cast<String, dynamic>()))
          .where((e) => e.id.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveAll(List<PendingUploadRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(records.map((e) => e.toJson()).toList());
    await prefs.setString(_prefsKey, encoded);
  }

  Future<void> upsert(PendingUploadRecord record) async {
    final list = (await loadAll()).toList(growable: true);
    final idx = list.indexWhere((e) => e.id == record.id);
    if (idx >= 0) {
      list[idx] = record;
    } else {
      list.add(record);
    }
    await saveAll(list);
  }

  Future<void> remove(String id) async {
    final list = (await loadAll()).toList(growable: true)
      ..removeWhere((e) => e.id == id);
    await saveAll(list);
  }

  /// Copy media into a stable folder so it survives app restarts/OS cache cleanup.
  ///
  /// Returns a record with updated file paths pointing to the persistent copies.
  Future<PendingUploadRecord> persistFiles(PendingUploadRecord record) async {
    final base = await _uploadQueueDir(record.id);
    await base.create(recursive: true);

    Future<String?> copyOne(String srcPath, String subDir) async {
      if (srcPath.trim().isEmpty) return null;
      final src = File(srcPath);
      if (!await src.exists()) return null;
      final dstDir = Directory(p.join(base.path, subDir));
      await dstDir.create(recursive: true);
      final name =
          '${DateTime.now().microsecondsSinceEpoch}_${p.basename(srcPath)}';
      final dstPath = p.join(dstDir.path, name);
      try {
        await src.copy(dstPath);
        return dstPath;
      } catch (_) {
        // If copy fails, fall back to original path
        return srcPath;
      }
    }

    final newImages = <String>[];
    for (final img in record.imagePaths) {
      final copied = await copyOne(img, 'images');
      if (copied != null) newImages.add(copied);
    }

    final newVideos = <String>[];
    for (final vid in record.videoPaths) {
      final copied = await copyOne(vid, 'videos');
      if (copied != null) newVideos.add(copied);
    }

    final newSig = record.signatureImagePath == null
        ? null
        : await copyOne(record.signatureImagePath!, 'signature');

    return record.copyWith(
      imagePaths: newImages,
      videoPaths: newVideos,
      signatureImagePath: newSig,
      updatedAt: DateTime.now(),
    );
  }

  Future<void> deletePersistedFiles(String id) async {
    final base = await _uploadQueueDir(id);
    if (await base.exists()) {
      try {
        await base.delete(recursive: true);
      } catch (_) {}
    }
  }

  Future<Directory> _uploadQueueDir(String id) async {
    final dir = await getApplicationSupportDirectory();
    return Directory(p.join(dir.path, 'upload_queue', id));
  }
}
