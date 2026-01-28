
import 'dart:math';
import 'package:encrypt/encrypt.dart';

class EncryptAndDecrypt {
  /// Encrypt and return URL-safe encoded string
  /// Base64-encoded 32-byte key from Flutter
  final String base64Key = 'PJC7HnliwcxXw4FM8Ep3sX9NIL3R5CZnDvp8IyyCSlg=';
  /// Convert base64 key into usable Key object
  Key get key => Key.fromBase64(base64Key);
  /// Secure padding scheme constant for AES encryption
  static const String _paddingScheme = 'PKCS7';
  /// Secure encryption mode constant for AES encryption
  static const AESMode _encryptionMode = AESMode.cbc;
  /// Creates an AES encrypter with secure mode and padding scheme
  Encrypter _createEncrypter() => Encrypter(AES(key, mode: _encryptionMode, padding: _paddingScheme));
  /// Generate a random 16-character IV (UTF-8 string)
  String generateRandomString({int length = 16}) {
    /// Allowed characters for the IV and it will be alphanumeric
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    /// Get the Random Secure for encryption security
    final rand = Random.secure();
    /// Generates a list of random characters and This string becomes the IV
    return List.generate(length, (index) =>
    chars[rand.nextInt(chars.length)]).join();
  }
  /// Encrypt: Returns 'ivString|cipherBase64'
  ///
  /// [urlEncode]: If true, URL-encodes the result (for query parameters).
  ///              If false, returns raw string (for request bodies).
  ///              Default: true (for backward compatibility)
  Future<String> encryption({
    required String payload,
    bool urlEncode = true,
  }) async {
    /// Generates a random 16-character IV string
    final ivString = generateRandomString(length: 16);
    /// Converts the IV string into bytes using UTF-8 encoding, AES-CBC
    // requires a 16-byte IV
    final iv = IV.fromUtf8(ivString);
    /// Creates an AES encrypter : 1.Call the Api key here, 2.AESMode.cbc →
    // Cipher Block Chaining mode
    final encrypter = _createEncrypter();
    /// Encrypts the plaintext using AES key and Random IV
    final encrypted = encrypter.encrypt(payload, iv: iv);
    /// Combines IV (as string) and Cipher text (Base64 encoded)
    final result = '$ivString|${encrypted.base64}';


    /// Url-encodes the results if requested (for query params, headers, or URLs)
    /// Otherwise returns raw string (for request bodies)
/*    if (urlEncode) {
      final encoded = Uri.encodeComponent(result);
      print("encrypted (URL-encoded): $encoded");
      return encoded;
    }*/
    return result;
  }

  /// Decrypt: Accepts 'ivString|cipherBase64'
  Future<String> decryption({
    required String payload,
  }) async {
    try {
      /// Splits input into IV and cipher text.
      final parts = payload.split('|');
      /// Throws error if IV or cipher text is missing or format is invalid.
      if (parts.length != 2) throw const FormatException('Invalid encrypted format');
      /// Extracts IV and encrypted data.
      final ivString = parts[0];
      final cipherBase64 = parts[1];
      /// Converts IV string back to bytes.
      final iv = IV.fromUtf8(ivString);
      /// Decodes Base64 cipher text into an Encrypted object.
      final encrypted = Encrypted.fromBase64(cipherBase64);
      /// Recreates the AES encrypter using the same key, mode, and padding.
      final encrypter = _createEncrypter();
      /// Decrypts the cipher text using the IV.
      final decrypted = encrypter.decrypt(encrypted, iv: iv);
      /// Returns the original plaintext.
      return decrypted;
    } catch (e) {
      return '';
    }
  }
}