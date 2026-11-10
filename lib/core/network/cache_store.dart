import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Persistent key/value storage for API responses. The remote API is always
/// the source of truth; the store only exists so a successful response keeps
/// working when the server later cannot be reached.
abstract class CacheStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

/// In-memory store for tests and as a safe fallback.
class MemoryCacheStore implements CacheStore {
  final Map<String, String> _entries = {};

  @override
  Future<String?> read(String key) async => _entries[key];

  @override
  Future<void> write(String key, String value) async {
    _entries[key] = value;
  }
}

/// File-backed store in the app-support directory, which Android keeps across
/// restarts and does not evict under storage pressure.
class FileCacheStore implements CacheStore {
  FileCacheStore({Directory? directory}) : _overrideDirectory = directory;

  final Directory? _overrideDirectory;
  Future<Directory>? _resolved;

  Future<Directory> _directory() {
    return _resolved ??= () async {
      final base = _overrideDirectory ?? await getApplicationSupportDirectory();
      final cache = Directory(
        '${base.path}${Platform.pathSeparator}api-cache',
      );
      await cache.create(recursive: true);
      return cache;
    }();
  }

  @override
  Future<String?> read(String key) async {
    try {
      final file = File(
        '${(await _directory()).path}'
        '${Platform.pathSeparator}${_fileName(key)}',
      );
      if (!await file.exists()) return null;
      return await file.readAsString();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String key, String value) async {
    try {
      final file = File(
        '${(await _directory()).path}'
        '${Platform.pathSeparator}${_fileName(key)}',
      );
      await file.writeAsString(value, flush: true);
    } catch (_) {
      // A failed cache write must never break a working network response.
    }
  }
}

/// Stable short file name for a cache key (FNV-1a, 64-bit). The stored
/// envelope re-checks the full key, so even a hash collision cannot serve the
/// wrong payload.
String _fileName(String key) {
  var hash = 0xcbf29ce484222325;
  for (final unit in key.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x100000001b3) & 0x7FFFFFFFFFFFFFFF;
  }
  return '${hash.toRadixString(16)}.json';
}
