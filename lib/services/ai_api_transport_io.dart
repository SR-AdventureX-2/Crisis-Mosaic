import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<Map<String, dynamic>> postJsonToAiApi(
  Uri uri,
  Map<String, Object?> body, {
  String? bearerToken,
  Duration timeout = const Duration(seconds: 12),
}) async {
  final client = HttpClient()..connectionTimeout = timeout;
  try {
    final request = await client.postUrl(uri).timeout(timeout);
    request.headers.contentType = ContentType.json;
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    if (bearerToken != null && bearerToken.isNotEmpty) {
      request.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer $bearerToken',
      );
    }
    request.add(utf8.encode(jsonEncode(body)));
    final response = await request.close().timeout(timeout);
    final responseText = await utf8.decoder.bind(response).join();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'AI API 返回 ${response.statusCode}: $responseText',
        uri: uri,
      );
    }
    final decoded = jsonDecode(responseText);
    if (decoded is! Map) {
      throw const FormatException('AI API 响应不是 JSON 对象。');
    }
    return decoded.cast<String, dynamic>();
  } finally {
    client.close(force: true);
  }
}
