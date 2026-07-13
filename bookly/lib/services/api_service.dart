import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:3000';

  static Uri _buildUri(String endpoint, [Map<String, String>? queryParams]) {
    return Uri.parse('$baseUrl$endpoint').replace(queryParameters: queryParams);
  }

  static Future<dynamic> get(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    final response = await http.get(
      _buildUri(endpoint, queryParams),
      headers: _headers,
    );

    return _handleResponse(response);
  }

  static Future<dynamic> post(
    String endpoint, {
    required Map<String, dynamic> body,
  }) async {
    final response = await http.post(
      _buildUri(endpoint),
      headers: _headers,
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  static Future<dynamic> put(
    String endpoint, {
    required Map<String, dynamic> body,
  }) async {
    final response = await http.put(
      _buildUri(endpoint),
      headers: _headers,
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  static Future<dynamic> patch(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final response = await http.patch(
      _buildUri(endpoint),
      headers: _headers,
      body: body == null ? null : jsonEncode(body),
    );

    return _handleResponse(response);
  }

  static Future<dynamic> delete(String endpoint) async {
    final response = await http.delete(_buildUri(endpoint), headers: _headers);

    return _handleResponse(response);
  }

  static Map<String, String> get _headers {
    return {'Content-Type': 'application/json', 'Accept': 'application/json'};
  }

  static dynamic _handleResponse(http.Response response) {
    final bool hasBody = response.body.isNotEmpty;

    final dynamic decodedBody = hasBody ? jsonDecode(response.body) : null;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decodedBody;
    }

    final String errorMessage = decodedBody is Map<String, dynamic>
        ? decodedBody['message']?.toString() ?? 'Erro inesperado na API.'
        : 'Erro inesperado na API.';

    throw Exception(errorMessage);
  }
}
