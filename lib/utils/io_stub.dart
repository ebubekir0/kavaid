// Web stub for dart:io File API used in sharing flows
// This file is used via conditional import on web to satisfy symbols.

class File {
  final String path;
  File(this.path);

  Future<void> writeAsBytes(List<int> bytes) async {}
  Future<void> delete() async {}
}

