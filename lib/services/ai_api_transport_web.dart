// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:html';

Future<Map<String, dynamic>> postJsonToAiApi(
  Uri uri,
  Map<String, Object?> body, {
  String? bearerToken,
  Duration timeout = const Duration(seconds: 12),
}) async {
  final headers = <String, String>{
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    if (bearerToken != null && bearerToken.isNotEmpty)
      'Authorization': 'Bearer $bearerToken',
  };
  final response = await HttpRequest.request(
    uri.toString(),
    method: 'POST',
    requestHeaders: headers,
    sendData: jsonEncode(body),
  ).timeout(timeout);
  final status = response.status ?? 0;
  if (status < 200 || status >= 300) {
    throw StateError('AI API 返回 $status: ${response.responseText ?? ''}');
  }
  final decoded = jsonDecode(response.responseText ?? '{}');
  if (decoded is! Map) {
    throw const FormatException('AI API 响应不是 JSON 对象。');
  }
  return decoded.cast<String, dynamic>();
}
