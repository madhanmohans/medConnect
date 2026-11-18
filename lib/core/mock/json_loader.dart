import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final jsonLoaderProvider = Provider<JsonLoader>((ref) => JsonLoader());

/// Loads mock JSON files from `assets/mock/`. Each entity lives in its own
/// file (e.g. `institutions.json`). Results are cached per file.
class JsonLoader {
  JsonLoader({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const basePath = 'assets/mock';

  final AssetBundle _bundle;
  final _cache = <String, Future<Object?>>{};

  Future<Object?> load(String fileName) => _cache.putIfAbsent(
    fileName,
    () async => jsonDecode(await _bundle.loadString('$basePath/$fileName')),
  );

  Future<List<Map<String, dynamic>>> loadList(String fileName) async {
    final data = await load(fileName);
    return (data! as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> loadMap(String fileName) async {
    final data = await load(fileName);
    return data! as Map<String, dynamic>;
  }
}
