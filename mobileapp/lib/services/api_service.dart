import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

/// Base API service — handles auth headers, error parsing, and timeouts.
class ApiService {
  ApiService._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const String _tokenKey = 'auth_token';

  // ─── Token Management ─────────────────────────────────────────────────────────
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ─── Headers ──────────────────────────────────────────────────────────────────
  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type':  'application/json',
      'Accept':        'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Map<String, String> _baseHeaders() => {
    'Content-Type': 'application/json',
    'Accept':       'application/json',
  };

  // ─── GET ──────────────────────────────────────────────────────────────────────
  static Future<ApiResponse> get(
    String url, {
    Map<String, String>? queryParams,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = Uri.parse(url).replace(
        queryParameters: queryParams?.map((k, v) => MapEntry(k, v)),
      );
      final headers = requiresAuth ? await _authHeaders() : _baseHeaders();

      final response = await http
          .get(uri, headers: headers)
          .timeout(ApiConfig.receiveTimeout);

      return _parseResponse(response);
    } on SocketException {
      return ApiResponse.networkError();
    } on HttpException {
      return ApiResponse.networkError();
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        return ApiResponse.error('Request timed out. Please try again.');
      }
      return ApiResponse.error('An unexpected error occurred.');
    }
  }

  // ─── POST JSON ────────────────────────────────────────────────────────────────
  static Future<ApiResponse> post(
    String url, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final uri     = Uri.parse(url);
      final headers = requiresAuth ? await _authHeaders() : _baseHeaders();

      final response = await http
          .post(uri, headers: headers, body: json.encode(body ?? {}))
          .timeout(ApiConfig.receiveTimeout);

      return _parseResponse(response);
    } on SocketException {
      return ApiResponse.networkError();
    } on HttpException {
      return ApiResponse.networkError();
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        return ApiResponse.error('Request timed out. Please try again.');
      }
      return ApiResponse.error('An unexpected error occurred.');
    }
  }

  // ─── POST Multipart (for file uploads) ───────────────────────────────────────
  static Future<ApiResponse> postMultipart(
    String url, {
    required Map<String, String> fields,
    File? imageFile,
    String imageFieldName = 'image',
    bool requiresAuth = true,
  }) async {
    try {
      final token   = requiresAuth ? await getToken() : null;
      final request = http.MultipartRequest('POST', Uri.parse(url));

      request.headers['Accept'] = 'application/json';
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.fields.addAll(fields);

      if (imageFile != null) {
        final mimeType = _getMimeType(imageFile.path);
        request.files.add(await http.MultipartFile.fromPath(
          imageFieldName,
          imageFile.path,
          contentType: mimeType,
        ));
      }

      final streamedResponse = await request.send().timeout(ApiConfig.receiveTimeout);
      final response = await http.Response.fromStream(streamedResponse);
      return _parseResponse(response);
    } on SocketException {
      return ApiResponse.networkError();
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        return ApiResponse.error('Upload timed out. Please try again.');
      }
      return ApiResponse.error('Upload failed. Please try again.');
    }
  }

  // ─── Response Parser ─────────────────────────────────────────────────────────
  static ApiResponse _parseResponse(http.Response response) {
    try {
      final body = json.decode(response.body) as Map<String, dynamic>;
      final success = body['success'] as bool? ?? false;
      final message = body['message'] as String? ?? 'Unknown error';
      final data    = body['data'];

      if (response.statusCode == 401) {
        return ApiResponse(success: false, message: message, data: data, statusCode: 401, isAuthError: true);
      }

      return ApiResponse(
        success:    success,
        message:    message,
        data:       data,
        statusCode: response.statusCode,
      );
    } catch (_) {
      if (response.statusCode >= 500) {
        return ApiResponse.error('Server error. Please try again later.');
      }
      return ApiResponse.error('Failed to parse server response.');
    }
  }

  static _MimeType _getMimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png'))  return _MimeType('image', 'png');
    if (lower.endsWith('.webp')) return _MimeType('image', 'webp');
    return _MimeType('image', 'jpeg');
  }
}

class _MimeType extends http.MediaType {
  _MimeType(super.type, super.subtype);
}

// ─── API Response Wrapper ─────────────────────────────────────────────────────
class ApiResponse {
  final bool    success;
  final String  message;
  final dynamic data;
  final int     statusCode;
  final bool    isNetworkError;
  final bool    isAuthError;

  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.statusCode      = 200,
    this.isNetworkError  = false,
    this.isAuthError     = false,
  });

  factory ApiResponse.networkError() => const ApiResponse(
    success:        false,
    message:        'No internet connection. Please check your network.',
    statusCode:     0,
    isNetworkError: true,
  );

  factory ApiResponse.error(String msg, [int code = 400]) => ApiResponse(
    success:    false,
    message:    msg,
    statusCode: code,
  );
}
