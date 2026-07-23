Future<Map<String, dynamic>> postJsonToAiApi(
  Uri uri,
  Map<String, Object?> body, {
  String? bearerToken,
  Duration timeout = const Duration(seconds: 12),
}) {
  throw UnsupportedError('当前平台不支持 AI HTTP 传输。');
}
