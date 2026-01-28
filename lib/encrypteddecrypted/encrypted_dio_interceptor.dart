import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../utils/constants.dart';
import 'encrypt_and_decrypt.dart';
import 'encryption_config.dart';


class EncryptedDioInterceptor extends Interceptor {
  final EncryptAndDecrypt _encryptAndDecrypt = EncryptAndDecrypt();

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      // Check if encryption is required for this endpoint
      if (!_shouldEncrypt(options)) {
        handler.next(options);
        return;
      }
      await _handleQueryEncryption(options);
      await _handleBodyEncryption(options);

      handler.next(options);
    } catch (e) {
      print('Dio Request Encryption Error: $e');
      handler.reject(
        DioException(
          requestOptions: options,
          error: e,
          type: DioExceptionType.badResponse,
        ),
      );
    }
  }

  bool _shouldEncrypt(RequestOptions options) {
    if (!EncryptionConfig.requiresEncryption(
      options.uri.toString(),
      headers: options.headers,
      method: options.method,
    )) {
      return false;
    }

    final contentType = options.headers['Content-Type']?.toString();
    return contentType?.contains('multipart/form-data') != true;
  }

  Future<void> _handleQueryEncryption(RequestOptions options) async {
    final queryParams = _extractQueryParameters(options);
    if (queryParams.isEmpty) return;

    final encryptedParams = <String, String>{};

    _logQueryEncryptionStart(options);

    for (final entry in queryParams.entries) {
      final encrypted = await _encryptAndDecrypt.encryption(
        payload: entry.value,
        urlEncode: true,
      );

      encryptedParams[entry.key] = Uri.decodeComponent(encrypted);

      _logQueryParam(entry.key, entry.value, encrypted);
    }

    options.queryParameters = encryptedParams;
  }

  Map<String, String> _extractQueryParameters(RequestOptions options) {
    final params = <String, String>{};

    if (options.path.contains('://')) {
      _extractFromFullUrl(options, params);
    } else if (options.path.contains('?')) {
      final uri = Uri.parse(options.path);
      params.addAll(uri.queryParameters);
      options.path = uri.path;
    }

    if (params.isEmpty && options.queryParameters.isNotEmpty) {
      params.addAll(
        options.queryParameters.map(
          (k, v) => MapEntry(k, v.toString()),
        ),
      );
    }

    return params;
  }

  void _extractFromFullUrl(
    RequestOptions options,
    Map<String, String> params,
  ) {
    final uri = Uri.parse(options.path);

    if (uri.hasQuery) {
      params.addAll(uri.queryParameters);
    }

    if (uri.hasScheme && uri.hasAuthority) {
      options.baseUrl = '${uri.scheme}://${uri.authority}';
      options.path = uri.path;
    }
  }

  Future<void> _handleBodyEncryption(RequestOptions options) async {
    if (options.data == null) return;

    final originalData = options.data;
    final dataString = _stringifyBody(originalData);

    _logBodyEncryptionStart(options, dataString, originalData);

    final encryptedPayload = await _encryptAndDecrypt.encryption(
      payload: dataString,
      urlEncode: false,
    );

    options.data = jsonEncode(encryptedPayload);
    _applyDefaultHeaders(options);
  }

  String _stringifyBody(dynamic data) {
    if (data is String) return data;
    if (data is Map || data is List) return jsonEncode(data);
    return data.toString();
  }

  void _logQueryParam(
    String key,
    String originalValue,
    String encryptedValue,
  ) {
    print('📝 Parameter Name: $key');
    print('   Original Value: $originalValue');
    print('   Encrypted Value (URL-encoded): $encryptedValue');
    print('   Decoded Value (for Dio): ${Uri.decodeComponent(encryptedValue)}');
    print(linePrint);
  }

  void _debugLog(void Function() log) {
    if (kDebugMode) {
      log();
    }
  }

  void _logBodyEncryptionStart(
    RequestOptions options,
    String dataString,
    dynamic originalData,
  ) {
    print(linePrint);
    print('🔒 DIO ${options.method.toUpperCase()} - Encrypting Request Body');
    print(linePrint);
    print('📝 Parameter Name: body');
    print('   Original Value: $dataString');

    if (originalData is Map) {
      print('   Body Parameters:');
      originalData.forEach((key, value) {
        print('      - $key: $value');
      });
    }
  }

  void _logQueryEncryptionStart(RequestOptions options) {
    _debugLog(() {
      print(linePrint);
      print(
          '🔒 DIO ${options.method.toUpperCase()} - Encrypting Query Parameters');
      print(linePrint);
    });
  }

  void _applyDefaultHeaders(RequestOptions options) {
    options.headers.putIfAbsent(
      'Content-Type',
      () => 'application/json; charset=utf-8',
    );
    options.headers.putIfAbsent('accept', () => 'text/plain');
  }

  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    try {
      if (!_shouldDecryptResponse(response)) {
        handler.next(response);
        return;
      }

      final responseData = response.data as Map<String, dynamic>;
      await _decryptResponseData(responseData);

      response.data = responseData;
      handler.next(response);
    } catch (e) {
      print('Dio Response Decryption Error: $e');
      handler.next(response);
    }
  }

  bool _shouldDecryptResponse(Response response) {
    if (!EncryptionConfig.requiresEncryption(
      response.requestOptions.uri.toString(),
      headers: response.requestOptions.headers,
      method: response.requestOptions.method,
    )) {
      return false;
    }

    return response.data != null && response.data is Map;
  }

  Future<void> _decryptResponseData(Map<String, dynamic> responseData) async {
    if (!responseData.containsKey('data')) return;

    final data = responseData['data'];

    if (data is String) {
      responseData['data'] = await _decryptSingle(data);
    } else if (data is List) {
      responseData['data'] = await _decryptList(data);
    }
  }

  Future<dynamic> _decryptSingle(String encrypted) async {
    try {
      final decrypted = await _encryptAndDecrypt.decryption(payload: encrypted);
      return decrypted.isNotEmpty ? jsonDecode(decrypted) : encrypted;
    } catch (e) {
      print('Single Response Decryption Error: $e');
      return encrypted;
    }
  }

  Future<List<dynamic>> _decryptList(List dataList) async {
    final decryptedList = <dynamic>[];

    for (final item in dataList) {
      if (item is String) {
        decryptedList.add(await _decryptSingle(item));
      } else {
        decryptedList.add(item);
      }
    }

    return decryptedList;
  }


  @override
  void onError(
    DioError err,
    ErrorInterceptorHandler handler,
  ) async {
    try {
      if (!_shouldDecryptError(err)) {
        handler.next(err);
        return;
      }

      final responseData = err.response!.data as Map<String, dynamic>;
      await _decryptResponseData(responseData);

      err.response!.data = responseData;
    } catch (e) {
      print('Dio Error Processing Error: $e');
    }
    handler.next(err);
  }

  bool _shouldDecryptError(DioError err) {
    if (!EncryptionConfig.requiresEncryption(
      err.requestOptions.uri.toString(),
      headers: err.requestOptions.headers,
      method: err.requestOptions.method,
    )) {
      return false;
    }

    return err.response != null &&
        err.response!.data != null &&
        err.response!.data is Map &&
        (err.response!.data as Map).containsKey('data');
  }
}
