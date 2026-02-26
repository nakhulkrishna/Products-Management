import 'external_url_stub.dart'
    if (dart.library.html) 'external_url_web.dart'
    as impl;

Future<bool> openExternalUrl(String url) {
  return impl.openExternalUrl(url);
}
