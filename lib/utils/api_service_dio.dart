import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:patrol_system/utils/store_user_data.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../encrypteddecrypted/encrypt_and_decrypt.dart';
import '../encrypteddecrypted/encryption_config.dart';
import 'constants.dart' as constants;
import 'constants.dart';

class ApiServiceDio {
  static ApiServiceDio? _instance;
  var storeUserData = StoreUserData();

  static const String _keepAlive = 'keep-alive';

  static ApiServiceDio get instance => _instance ??= ApiServiceDio._();
  late final Dio _dio;
  bool isDebug = kDebugMode;

  Future<Map<String, String>> getHeaders() async {
    Map<String, String> headers;
    if (storeUserData.getString(constants.USER_TOKEN).isNotEmpty) {
      headers = {
        'Accept-Language': "EN",
        'Authorization': storeUserData.getString(constants.USER_TOKEN),
        'accept': "text/plain",
        'Connection': _keepAlive,
        'Accept-Encoding': 'gzip, deflate, br',
        'Cache-Control': _keepAlive,
      };
    } else {
      headers = {
        'accept': "text/plain",
        'Content-Type': "application/json-patch+json",
        'Accept-Encoding': 'gzip, deflate, br',
        'Cache-Control': _keepAlive,
        'Connection': _keepAlive,
      };
    }
    print("headers : $headers");
    return headers;
  }

  ApiServiceDio._() {
    _initializeDio();
  }

  Future<void> _initializeDio() async {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 120),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 60),
      headers: await getHeaders(),
      responseType: ResponseType.json,
      // Auto-parse JSON responses
      validateStatus: (status) => status != null && status < 500,
    ));

    _setupInterceptors();
    _configureHttpAdapter();
  }

  void _setupInterceptors() {
    // Encryption/Decryption interceptor (must be first)
    _dio.interceptors.add(_EncryptionInterceptor());

    // Request/Response logging (debug mode only)
    if (isDebug) {
      _dio.interceptors.add(PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
        compact: true,
        maxWidth: 120,
      ));
    }

    // Custom timing interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        options.extra['start_time'] = DateTime.now().millisecondsSinceEpoch;
        handler.next(options);
      },
      onResponse: (response, handler) {
        if (isDebug) {
          final startTime = response.requestOptions.extra['start_time'] as int?;
          if (startTime != null) {
            final duration = DateTime.now().millisecondsSinceEpoch - startTime;
            final now = DateTime.now();
            final formattedTime = "${now.hour.toString().padLeft(2, '0')}:"
                "${now.minute.toString().padLeft(2, '0')}:"
                "${now.second.toString().padLeft(2, '0')}";

            debugPrint(
                "${response.requestOptions.method} ${response.requestOptions.path} → ${duration}ms at $formattedTime");
          }
        }
        handler.next(response);
      },
      onError: (error, handler) {
        _logError(error);
        handler.next(error);
      },
    ));

    /*  // Retry interceptor for network failures
    _dio.interceptors.add(RetryInterceptor(
      dio: _dio,
      logPrint: kDebugMode ? debugPrint : null,
    ));*/
  }

  void _configureHttpAdapter() {
    if (_dio.httpClientAdapter is IOHttpClientAdapter) {
      final adapter = _dio.httpClientAdapter as IOHttpClientAdapter;
      adapter.createHttpClient = () {
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 120);
        client.idleTimeout = const Duration(minutes: 5);
        client.maxConnectionsPerHost = 15;
        return client;
      };
    }
  }

  void _logError(DioException error) {
    if (!isDebug) return;

    debugPrint('🔥 API Error: ${error.type}');
    debugPrint('📍 URL: ${error.requestOptions.uri}');
    debugPrint('📊 Status: ${error.response?.statusCode}');
    debugPrint('💬 Message: ${error.message}');
    if (error.response?.data != null) {
      debugPrint('📦 Response: ${error.response?.data}');
    }
  }

  Future<ApiResponse<T>> _request<T>(
    Future<Response> Function() apiCall,
  ) async {
    try {
      final response = await apiCall();
      return _handleResponse<T>(response);
    } on DioException catch (e) {
      return _handleError<T>(e);
    } catch (e) {
      return ApiResponse.error('Unexpected error: $e');
    }
  }

  Future<ApiResponse<T>> post<T>(String endpoint, Map<String, dynamic> data) {
    return _request(() => _dio.post(endpoint, data: data));
  }

// Example usage:
  Future<ApiResponse<T>> get<T>(String endpoint,
      {Map<String, dynamic>? queryParameters}) {
    return _request(() => _dio.get(endpoint, queryParameters: queryParameters));
  }

  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        options: options?.copyWith(
              contentType: Headers.jsonContentType,
            ) ??
            Options(contentType: Headers.jsonContentType),
      );

      return _handleResponse<T>(response);
    } on DioException catch (e) {
      return _handleError<T>(e);
    } catch (e) {
      return ApiResponse.error('Unexpected error: $e');
    }
  }

  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        endpoint,
        queryParameters: queryParameters,
        options: options,
      );

      return _handleResponse<T>(response);
    } on DioException catch (e) {
      return _handleError<T>(e);
    } catch (e) {
      return ApiResponse.error('Unexpected error: $e');
    }
  }

  Future<ApiResponse<T>> uploadFiles<T>(
    String endpoint,
    Map<String, String> fields,
    List<String> filePaths,
    String fileFieldName,
  ) async {
    try {
      final formData = FormData();

      // Add text fields
      fields.forEach((key, value) {
        formData.fields.add(MapEntry(key, value));
      });

      // Add files
      for (int i = 0; i < filePaths.length; i++) {
        final file = await MultipartFile.fromFile(
          filePaths[i],
          filename: filePaths[i].split('/').last,
        );
        formData.files.add(MapEntry(fileFieldName, file));
      }

      final response = await _dio.post(
        endpoint,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      return _handleResponse<T>(response);
    } on DioException catch (e) {
      return _handleError<T>(e);
    } catch (e) {
      return ApiResponse.error('Upload failed: $e');
    }
  }

  Future<ApiResponse<T>> uploadSingleFile<T>(
    String endpoint,
    Map<String, String> fields,
    String filePath,
    String emiratedIdBack,
  ) async {
    return uploadFiles<T>(
      endpoint,
      fields,
      [filePath],
      emiratedIdBack,
    );
  }

  Future<ApiResponse<T>> uploadSingleFileFromBytes<T>(
    String endpoint,
    Map<String, String> fields,
    List<int> fileBytes, {
    String fileFieldName = 'file',
    String? fileName,
  }) async {
    try {
      final formData = FormData();

      // Add text fields
      fields.forEach((key, value) {
        formData.fields.add(MapEntry(key, value));
      });

      // Add file from bytes
      formData.files.add(
        MapEntry(
          fileFieldName,
          MultipartFile.fromBytes(
            fileBytes,
            filename:
                fileName ?? '${DateTime.now().millisecondsSinceEpoch}.jpg',
            // contentType: Headers.parseMediaType('image/jpeg'),
          ),
        ),
      );

      final response = await _dio.post(
        endpoint,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
        // onSendProgress: onSendProgress,
      );

      return _handleResponse<T>(response);
    } on DioException catch (e) {
      return _handleError<T>(e);
    } catch (e) {
      return ApiResponse.error('Upload failed: $e');
    }
  }

  Future<ApiResponse<T>> postBarcode<T>(
    String endpoint,
    String barcode,
  ) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: barcode,
        options: Options(
          contentType: Headers.jsonContentType,
        ),
      );

      return _handleResponse<T>(response);
    } on DioException catch (e) {
      return _handleError<T>(e);
    } catch (e) {
      return ApiResponse.error('Barcode API error: $e');
    }
  }

  // --- Response Handlers ---

  ApiResponse<T> _handleResponse<T>(Response response) {
    final statusCode = response.statusCode ?? 0;

    if (statusCode >= 200 && statusCode < 300) {
      return ApiResponse.success(response.data as T, statusCode);
      // return ApiResponse.success(responseData as T, statusCode);
    } else {
      final errorMessage = _extractErrorMessage(response.data);
      return ApiResponse.error(errorMessage, statusCode);
    }
  }

  ApiResponse<T> _handleError<T>(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiResponse.error(
            "Connection timeout. Please check your internet connection.", 500);

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 0;
        final errorMessage = _extractErrorMessage(error.response?.data);
        return ApiResponse.error(errorMessage, statusCode);

      case DioExceptionType.cancel:
        return ApiResponse.error('Request was cancelled.');

      case DioExceptionType.connectionError:
        return ApiResponse.error('No internet connection available.');

      case DioExceptionType.badCertificate:
        return ApiResponse.error('Certificate verification failed.');

      case DioExceptionType.unknown:
        return ApiResponse.error('Network error occurred.');
    }
  }

  String _extractErrorMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['message'] ??
          data['error'] ??
          data['detail'] ??
          'Unknown server error';
    } else if (data is String) {
      return data.isNotEmpty ? data : 'Server returned empty response';
    }
    return 'Unknown error format';
  }

  // --- Utility Methods ---

  void updateAuthToken(String newToken) {
    _dio.options.headers['Authorization'] = newToken;
  }

  Future<void> fcmTokenSend() async {
    try {
      var encryptAndDecrypt = EncryptAndDecrypt();
      var departmentUserId = await encryptAndDecrypt.encryption(
          payload: storeUserData.getInt(USER_ID).toString(), urlEncode: false);
      var fcmToken = await encryptAndDecrypt.encryption(
          payload: storeUserData.getString(USER_FCM).toString(),
          urlEncode: false);
      final response = await instance.put(
        "api/Mobile/Notification/UpdateFcmToken"
        "?departmentUserId=${Uri.encodeComponent(departmentUserId)}"
        "?fcmToken=${Uri.encodeComponent(fcmToken)}",
      );
      if (response.isSuccess) {
        debugPrint("✅ FCM Token updated: ${response.data}");
      } else {
        debugPrint("⚠️ Failed to update FCM Token: ${response.error}");
      }
    } catch (e, s) {
      debugPrint("🔥 fcmTokenSend() error: $e\n$s");
    }
  }

  void dispose() {
    _dio.close();
  }
}

// --- Response Wrapper ---

class ApiResponse<T> {
  final bool isSuccess;
  final T? data;
  final String? error;
  final int? statusCode;

  const ApiResponse._({
    required this.isSuccess,
    this.data,
    this.error,
    this.statusCode,
  });

  factory ApiResponse.success(T data, [int? statusCode]) => ApiResponse._(
        isSuccess: true,
        data: data,
        statusCode: statusCode,
      );

  factory ApiResponse.error(String error, [int? statusCode]) => ApiResponse._(
        isSuccess: false,
        error: error,
        statusCode: statusCode,
      );

  bool get isError => !isSuccess;
}

// --- Encryption Interceptor ---

class _EncryptionInterceptor extends Interceptor {
  final EncryptAndDecrypt _encryptAndDecrypt = EncryptAndDecrypt();

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final requiresEncryption = EncryptionConfig.requiresEncryption(
      options.path,
      headers: options.headers,
      method: options.method,
    );

    if (!requiresEncryption) {
      handler.next(options);
      return;
    }

    try {
      // Extract query parameters from URI if not already parsed
      Map<String, dynamic> queryParams =
          Map<String, dynamic>.from(options.queryParameters);
      if (queryParams.isEmpty && options.uri.hasQuery) {
        queryParams = Map<String, dynamic>.from(options.uri.queryParameters);
      }

      // Encrypt query parameters for GET requests
      if (queryParams.isNotEmpty) {
        final encryptedParams = <String, dynamic>{};
        for (final entry in queryParams.entries) {
          final value = entry.value?.toString() ?? '';
          if (value.isNotEmpty) {
            final encryptedValue = await _encryptAndDecrypt.encryption(
              payload: value,
              urlEncode: true,
            );
            encryptedParams[entry.key] = encryptedValue;
          } else {
            encryptedParams[entry.key] = entry.value;
          }
        }
        options.queryParameters = encryptedParams;
      }

      // Encrypt request body for POST/PUT requests
      if (options.data != null) {
        final bodyString = options.data is String
            ? options.data as String
            : jsonEncode(options.data);
        final encryptedBody = await _encryptAndDecrypt.encryption(
          payload: bodyString,
          urlEncode: false,
        );
        options.data = jsonEncode(encryptedBody);
        options.headers['Content-Type'] = 'application/json';
      }
    } catch (e) {
      debugPrint('Encryption error: $e');
    }

    handler.next(options);
  }

  @override
  Future<void> onResponse(
      Response response, ResponseInterceptorHandler handler) async {
    final requiresEncryption = EncryptionConfig.requiresEncryption(
      response.requestOptions.path,
      headers: response.requestOptions.headers,
      method: response.requestOptions.method,
    );

    if (!requiresEncryption || response.data == null) {
      handler.next(response);
      return;
    }

    try {
      final responseData = response.data;

      // Check if the encrypted payload is inside a 'data' key
      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('data')) {
        final encryptedData = responseData['data'];
        if (encryptedData != null) {
          final decryptedData = await _decryptResponseData(encryptedData);
          responseData['data'] = decryptedData;
          response.data = responseData;
        }
      }
      // If the encrypted payload comes directly in the response
      else if (responseData is String) {
        final decryptedData = await _decryptResponseData(responseData);
        response.data = decryptedData;
      }
      // If response is a List, decrypt each item
      else if (responseData is List) {
        final decryptedList = await _decryptList(responseData);
        response.data = decryptedList;
      }
    } catch (e) {
      debugPrint('Decryption error: $e');
    }

    handler.next(response);
  }

  Future<dynamic> _decryptResponseData(dynamic data) async {
    if (data is String) {
      return await _decryptSingleItem(data);
    }

    if (data is List) {
      return await _decryptList(data);
    }

    return data;
  }

  Future<dynamic> _decryptSingleItem(String encrypted) async {
    try {
      final decrypted = await _encryptAndDecrypt.decryption(
        payload: encrypted,
      );
      if (decrypted.isNotEmpty) {
        return jsonDecode(decrypted);
      }
      return encrypted;
    } catch (e) {
      debugPrint('Single response decryption error: $e');
      return encrypted;
    }
  }

  Future<List<dynamic>> _decryptList(List data) async {
    final decryptedList = <dynamic>[];

    for (final item in data) {
      if (item is String) {
        try {
          final decrypted = await _encryptAndDecrypt.decryption(
            payload: item,
          );
          if (decrypted.isNotEmpty) {
            decryptedList.add(jsonDecode(decrypted));
            continue;
          }
        } catch (e) {
          debugPrint('List item decryption error: $e');
        }
      }
      decryptedList.add(item);
    }

    return decryptedList;
  }
}

// --- Extension for easy access ---

extension ApiExtensionDioExtension on BuildContext {
  ApiServiceDio get apiDio => ApiServiceDio.instance;
}
