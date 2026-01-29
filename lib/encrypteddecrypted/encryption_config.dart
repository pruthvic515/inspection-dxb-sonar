import 'package:flutter/foundation.dart';

/// Configuration class for API encryption
///https://docs.google.com/document/d/1Gxupux0pVCn-MLw1NR3nAh1DuF0s9vXObWFEuIswTck/edit?usp=sharing
/// Usage:
/// 1. Add endpoint patterns to encryptedEndpoints list to enable encryption for all methods
/// 2. Add method-specific rules to encryptedEndpointsByMethod for specific HTTP methods
/// 3. Add endpoint patterns to excludedEndpoints to explicitly disable encryption
/// 4. Or use X-Require-Encryption header in individual requests
///
/// **AI Tools Prompt**
///
/// * All **request data is encrypted** before sending.
/// * All **API responses are received in encrypted format**.
/// * **Decryption must be applied before using the response data**.
///
/// **Rules:**
///
/// 1. Do not change any existing business logic
/// 2. Always **check the API response structure**:
///
///    * If the encrypted payload is inside a `data` key → decrypt that value.
///    * If the encrypted payload comes **directly in the response** → decrypt the full response.
/// 3. Use the **decrypted response only** for further processing.
class EncryptionConfig {
  // Header name to enable encryption for a specific request
  static const String encryptionHeader = 'X-Require-Encryption';

  static final Map<String, List<String>> encryptedEndpointsByMethod = {
    'GET': [
      // GET methods that require encryption
      'api/Department/Task/GetTaskStatus',
      'api/Department/User/GetInspectionList',
      'api/Department/User/GetAllUser',
      'api/Mobile/Entity/GetAllEntityBasicDetail',
      "api/Mobile/ProduectDetail/GetProductCategory"
    ],
    'POST': [
      // POST methods that require encryption
      'api/Department/Task/GetTask',
      'api/Department/Task/GetAll',
      'api/Department/Task/UpdateTaskStatus',
      'api/Department/Task/UpdateInspectionTaskStatus',
      'api/Mobile/Entity/GetEntity',
      'api/Mobile/Entity/GetPatrolLogs',
      'api/Mobile/Entity/GetEntityInspectionDetails',
      'api/Mobile/Inspection/GetInspectionDetails',
      'api/Mobile/Inspection/CreateInspection',
      'api/Mobile/Inspection/UpdateInspection',
      'api/Mobile/ProduectDetail/GetAllProduct',
      'api/Mobile/ProduectDetail/Create',
      'api/Mobile/ProduectDetail/Update',
      'api/Mobile/ProduectDetail/Delete',

    ],
  };


  // List of API endpoint patterns that should NOT use encryption (for all methods)
  // These take priority over encryptedEndpoints
  static final List<String> excludedEndpoints = [

  ];



  /// Check if an endpoint requires encryption
  ///
  /// Priority:
  /// 1. X-Require-Encryption header (if set, use that value)
  /// 2. excludedEndpointsByMethod (if matches for the method, return false)
  /// 3. excludedEndpoints (if matches, return false)
  /// 4. encryptedEndpointsByMethod (if matches for the method, return true)
  /// 5. encryptedEndpoints (if matches, return true)
  /// 6. If all lists are empty, return false (encryption disabled by default)
  static bool _requiresEncryption(
      String path, {
        Map<String, dynamic>? headers,
        String? method,
      }) {
    final httpMethod = _normalizeMethod(method);

    final headerDecision = _encryptionFromHeader(headers);
    if (headerDecision != null) {
      return headerDecision;
    }

    final pathToCheck = _extractPath(path);

    if (_isExcluded(pathToCheck, path)) {
      return false;
    }

    if (_isEncryptedForMethod(pathToCheck, path, httpMethod)) {
      return true;
    }

    return false;
  }

  static bool requiresEncryption(
      String path, {
        Map<String, dynamic>? headers,
        String? method,
      }) {
    final httpMethod = _normalizeMethod(method);

    final headerDecision = _encryptionFromHeader(headers);
    if (headerDecision != null) {
      return headerDecision;
    }

    final pathToCheck = _extractPath(path);

    if (_isEncryptedForMethod(pathToCheck, path, httpMethod)) {
      return true;
    }

    if (_isExcluded(pathToCheck, path)) {
      return false;
    }

    return false;
  }
  static String _normalizeMethod(String? method) {
    return (method ?? 'GET').toUpperCase();
  }
  static bool? _encryptionFromHeader(Map<String, dynamic>? headers) {
    if (headers == null || !headers.containsKey(encryptionHeader)) {
      return null;
    }

    final value = headers[encryptionHeader];
    return value == true || value == 'true' || value == '1';
  }

  static String _extractPath(String path) {
    try {
      if (!path.contains('://')) return path;

      final uri = Uri.parse(path);
      return uri.hasQuery ? '${uri.path}?${uri.query}' : uri.path;
    } catch (_) {
      return path;
    }
  }
  static bool _isExcluded(String pathToCheck, String originalPath) {
    for (final excluded in excludedEndpoints) {
      if (_matchesPattern(pathToCheck, excluded)) {
        debugPrint(
          "❌ excludedEndpoints: $excluded matches $pathToCheck (from $originalPath)",
        );
        return true;
      }
    }
    return false;
  }
  static bool _isEncryptedForMethod(
      String pathToCheck,
      String originalPath,
      String httpMethod,
      ) {
    final patterns = encryptedEndpointsByMethod[httpMethod];
    if (patterns == null) {
      debugPrint("❌ No patterns found for method: $httpMethod");
      return false;
    }

    for (final pattern in patterns) {
      if (_matchesPattern(pathToCheck, pattern)) {
        debugPrint(
          "✅ encryptedEndpointsByMethod[$httpMethod]: "
              "$pattern matches",
        );
        return true;
      }
    }
    debugPrint("❌ No pattern matched for path: $pathToCheck");
    return false;
  }
  static bool _matchesPattern(String path, String pattern) {
    if (_isExactMatch(path, pattern)) return true;
    if (_matchesEnd(path, pattern)) return true;
    if (_matchesStart(path, pattern)) return true;
    if (_matchesSlashPattern(path, pattern)) return true;
    if (_matchesPatternWithBoundaries(path, pattern)) return true;

    return false;
  }

  static bool _isExactMatch(String path, String pattern) {
    return path == pattern;
  }

  static bool _matchesEnd(String path, String pattern) {
    return path.endsWith('/$pattern') || path.endsWith(pattern);
  }

  static bool _matchesStart(String path, String pattern) {
    if (!path.startsWith(pattern)) return false;
    if (path.length == pattern.length) return true;

    if (path.length > pattern.length) {
      final nextChar = path[pattern.length];
      return nextChar == '/' || nextChar == '?';
    }

    return false;
  }

  static bool _matchesSlashPattern(String path, String pattern) {
    final slashPattern = '/$pattern';
    if (!path.contains(slashPattern)) return false;

    final index = path.indexOf(slashPattern);
    if (!_isValidStartBoundary(path, index)) return false;

    final nextIndex = index + slashPattern.length;
    return _isValidEndBoundary(path, nextIndex);
  }

  static bool _matchesPatternWithBoundaries(String path, String pattern) {
    if (!path.contains(pattern)) return false;

    final index = path.indexOf(pattern);
    if (index <= 0 || path[index - 1] != '/') return false;

    final nextIndex = index + pattern.length;
    return _isValidEndBoundary(path, nextIndex);
  }

  static bool _isValidStartBoundary(String path, int index) {
    return index == 0 || (index > 0 && path[index - 1] == '/');
  }

  static bool _isValidEndBoundary(String path, int nextIndex) {
    if (nextIndex >= path.length) return true;
    final char = path[nextIndex];
    return char == '/' || char == '?';
  }


  /// Enable encryption for all APIs (use with caution)
  static void enableForAll() {
    // This would require modifying the logic, but for now,
    // you can add a wildcard pattern or set the header globally
  }

}
