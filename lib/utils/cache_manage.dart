import 'dart:io';

import 'package:PiliPlus/utils/extension.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:path_provider/path_provider.dart';

abstract class CacheManage {
  static Directory _desktopImageCacheDirectory(Directory tempDirectory) =>
      Directory('${tempDirectory.path}/libCachedImageData');

  static File _dioCacheFile(Directory directory) => File(
    '${directory.path}${Platform.pathSeparator}DioCache.db',
  );

  // 获取缓存目录
  static Future<int> loadApplicationCache() async {
    /// clear all of image in memory
    // clearMemoryImageCache();
    /// get ImageCache
    // var res = getMemoryImageCache();

    // 缓存大小
    // cached_network_image directory
    final tempDirectory = await getTemporaryDirectory();
    if (Utils.isDesktop) {
      return getTotalSizeOfFilesInDir(
        _desktopImageCacheDirectory(tempDirectory),
      );
    }
    // get_storage directory
    final docDirectory = await getApplicationDocumentsDirectory();
    final cacheSizes = await Future.wait<int>([
      getTotalSizeOfFilesInDir(tempDirectory),
      getTotalSizeOfFilesInDir(_dioCacheFile(docDirectory)),
    ]);
    return cacheSizes.fold(0, (total, size) => total + size);
  }

  // 循环计算文件的大小（递归）
  static Future<int> getTotalSizeOfFilesInDir(
    final FileSystemEntity file,
  ) async {
    if (!await file.exists()) {
      return 0;
    }
    if (file is File) {
      return file.length();
    }
    if (file is Directory) {
      var total = 0;
      await for (final child in file.list(followLinks: false)) {
        total += await getTotalSizeOfFilesInDir(child);
      }
      return total;
    }
    return 0;
  }

  // 缓存大小格式转换
  static String formatSize(num value) {
    List<String> unitArr = const ['B', 'K', 'M', 'G', 'T', 'P'];
    int index = 0;
    while (value >= 1024) {
      index++;
      value = value / 1024;
    }
    String size = value.toStringAsFixed(2);
    return size + unitArr.getOrElse(index, orElse: () => '');
  }

  /// 清除 Documents 目录下的 DioCache.db
  static Future<void> clearApplicationCache() async {
    final directory = await getApplicationDocumentsDirectory();
    await deleteDirectory(_dioCacheFile(directory));
  }

  // 清除 Library/Caches 目录及文件缓存
  static Future<void> clearLibraryCache() async {
    final tempDirectory = await getTemporaryDirectory();
    if (Utils.isDesktop) {
      await deleteDirectory(_desktopImageCacheDirectory(tempDirectory));
      return;
    }
    if (!await tempDirectory.exists()) {
      return;
    }
    await for (final file in tempDirectory.list(followLinks: false)) {
      await deleteDirectory(file);
    }
  }

  /// 递归方式删除目录及文件
  static Future<void> deleteDirectory(FileSystemEntity file) async {
    if (!await file.exists()) {
      return;
    }
    await file.delete(recursive: true);
  }

  static Future<void> autoClearCache() async {
    if (Pref.autoClearCache) {
      await clearLibraryCache();
    } else {
      final maxCacheSize = Pref.maxCacheSize;
      if (maxCacheSize != 0) {
        final currCache = await loadApplicationCache();
        if (currCache >= maxCacheSize) {
          await clearLibraryCache();
        }
      }
    }
  }
}
