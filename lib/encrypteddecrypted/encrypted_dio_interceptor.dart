import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api.dart';
import '../utils/constants.dart';
import 'encrypt_and_decrypt.dart';
import 'encryption_config.dart';


class EncryptedHttpClient {
  final EncryptAndDecrypt _encryptAndDecrypt = EncryptAndDecrypt();

  Future<http.Response> get(
      Uri url, {
        Map<String, String>? headers,
      }) async {
    try {
      // Check if encryption is required for this endpoint
      final requiresEncryption = EncryptionConfig.requiresEncryption(
        url.toString(),
        headers: headers,
        method: 'GET',
      );

      // If encryption is not required, use normal HTTP client
      if (!requiresEncryption) {
        final response = await http.get(url, headers: headers ?? {});
        return response;
      }

      Uri encryptedUrl = url;

      // Encrypt query parameters if present
      if (url.hasQuery) {
        final queryParams = url.queryParameters;
        final encryptedParams = <String, String>{};
        // Encrypt each query parameter value
        for (var entry in queryParams.entries) {
          final encryptedValue = await _encryptAndDecrypt.encryption(
            payload: entry.value,
          );
          // Use encryptedRequest as parameter name or keep original name
          encryptedParams[entry.key] = encryptedValue;
        }
        print('$linePrint\n');

        // Rebuild URL with encrypted parameters
        encryptedUrl = url.replace(queryParameters: encryptedParams);
      }
      print("encrypted request Url : $encryptedUrl");

      final response = await http.get(encryptedUrl, headers: headers ?? {});

      // Decrypt response if encrypted
      return await _processResponse(response);
    } catch (e) {
      print('Encrypted HTTP GET Error: $e');
      rethrow;
    }
  }

  Future<http.Response> post(
      Uri url, {
        Map<String, String>? headers,
        Object? body,
        Encoding? encoding,
      }) async {
    try {
      // Check if encryption is required for this endpoint
      final requiresEncryption = EncryptionConfig.requiresEncryption(
        url.toString(),
        headers: headers,
        method: 'POST',
      );

      // If encryption is not required, use normal HTTP client
      if (!requiresEncryption) {
        final response = await http.post(
          url,
          headers: headers ?? {},
          body: body,
          encoding: encoding,
        );
        return response;
      }

      String? encryptedBody;

      // Encrypt request body if provided
      if (body != null) {
        final bodyString = body is String ? body : jsonEncode(body);
        print('   Original Value: $bodyString');
        // Encrypt without URL encoding for request body
        final encryptedValue = await _encryptAndDecrypt.encryption(
          payload: bodyString,
          urlEncode: false, // Request body doesn't need URL encoding
        );
        print('   Encrypted Value (raw for body): $encryptedValue');
        encryptedBody = jsonEncode(encryptedValue);
      }

      // Create headers - preserve original headers, use application/json for Content-Type
      final requestHeaders =  {
        ...await Api().getHeaders(),
        ...?headers,
      };

      // Make request with encrypted data
      // Send encrypted string as JSON string: "encryptedValue" (matches Swagger)
      final response = await http.post(
        url,
        headers: requestHeaders,
        body: encryptedBody, // Send as JSON string: "encryptedValue"
        encoding: encoding,
      );

      // Decrypt response if encrypted
      return await _processResponse(response);
    } catch (e) {
      print('Encrypted HTTP POST Error: $e');
      rethrow;
    }
  }

  Future<http.Response> _processResponse(http.Response response) async {
    try {
      if (response.body.isEmpty) return response;

      final responseData = _tryParseJson(response.body);

      // If response is not JSON, check if it's directly encrypted string
      if (responseData == null) {
        // Try to decrypt the full response body as a string
        try {
          final decrypted = await _decryptSingleItem(response.body);
          if (decrypted != response.body) {
            return _buildNewResponse(response, decrypted);
          }
        } catch (e) {
          // If decryption fails, return original response
        }
        return response;
      }

      // Check if the encrypted payload is inside a 'data' key
      if (responseData is Map && responseData.containsKey('data')) {
        final decryptedData = await _decryptResponseData(responseData['data']);
        responseData['data'] = decryptedData;
        return _buildNewResponse(response, responseData);
      }

      // If the encrypted payload comes directly in the response (as a string)
      if (responseData is String) {
        final decrypted = await _decryptSingleItem(responseData);
        return _buildNewResponse(response, decrypted);
      }

      // If response is a List, decrypt each item
      if (responseData is List) {
        final decryptedList = await _decryptList(responseData);
        return _buildNewResponse(response, decryptedList);
      }

      return response;
    } catch (e) {
      print('Response Processing Error: $e');
      return response;
    }
  }

  dynamic _tryParseJson(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }


  Future<dynamic> _decryptResponseData(dynamic data) async {
    if (data is String) {
      return _decryptSingleItem(data);
    }

    if (data is List) {
      return _decryptList(data);
    }

    return data;
  }

  Future<dynamic> _decryptSingleItem(String encrypted) async {
    try {
      final decrypted = await _encryptAndDecrypt.decryption(payload: encrypted);

      return decrypted.isNotEmpty ? jsonDecode(decrypted) : encrypted;
    } catch (e) {
      print('Single Response Decryption Error: $e');
      return encrypted;
    }
  }

  Future<List<dynamic>> _decryptList(List data) async {
    final decryptedList = <dynamic>[];

    for (final item in data) {
      if (item is String) {
        try {
          final decrypted = await _encryptAndDecrypt.decryption(payload: item);

          if (decrypted.isNotEmpty) {
            decryptedList.add(jsonDecode(decrypted));
            continue;
          }
        } catch (e) {
          print('List Item Decryption Error: $e');
        }
      }
      decryptedList.add(item);
    }

    return decryptedList;
  }

  http.Response _buildNewResponse(
      http.Response response, dynamic responseData) {
    String body;
    if (responseData is String) {
      // If it's already a string, use it directly (might be JSON string or plain text)
      body = responseData;
    } else {
      // Otherwise, encode it as JSON
      body = jsonEncode(responseData);
    }

    return http.Response(
      body,
      response.statusCode,
      headers: response.headers,
      request: response.request,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }

}
