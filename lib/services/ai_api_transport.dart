import 'ai_api_transport_stub.dart'
    if (dart.library.io) 'ai_api_transport_io.dart'
    if (dart.library.html) 'ai_api_transport_web.dart'
    as implementation;

Future<Map<String, dynamic>> postJsonToAiApi(
  Uri uri,
  Map<String, Object?> body, {
  String? bearerToken,
  Duration timeout = const Duration(seconds: 12),
}) {
  return implementation.postJsonToAiApi(
    uri,
    body,
    bearerToken: bearerToken,
    timeout: timeout,
  );
}
