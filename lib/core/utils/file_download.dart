import 'file_download_stub.dart'
    if (dart.library.html) 'file_download_web.dart'
    as impl;

Future<bool> downloadBytesFile({
  required List<int> bytes,
  required String fileName,
  required String mimeType,
}) {
  return impl.downloadBytesFile(
    bytes: bytes,
    fileName: fileName,
    mimeType: mimeType,
  );
}
