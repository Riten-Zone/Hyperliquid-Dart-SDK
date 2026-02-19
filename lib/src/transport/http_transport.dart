/// HTTP transport layer for Hyperliquid REST API calls.
library;

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../utils/constants.dart';

/// Exception thrown when the Hyperliquid API returns an error.
class HyperliquidApiException implements Exception {
  final int statusCode;
  final String message;
  final String? body;

  const HyperliquidApiException({
    required this.statusCode,
    required this.message,
    this.body,
  });

  @override
  String toString() =>
      'HyperliquidApiException($statusCode): $message${body != null ? '\n$body' : ''}';
}

/// HTTP transport for making REST API calls to Hyperliquid.
///
/// Handles JSON serialization, error handling, and endpoint routing.
class HttpTransport {
  final http.Client _client;
  final bool isTestnet;

  /// Create a new HTTP transport.
  ///
  /// Pass a custom [client] for testing or to configure timeouts.
  HttpTransport({
    http.Client? client,
    this.isTestnet = false,
  }) : _client = client ?? http.Client();

  /// The base info URL for this transport.
  String get infoUrl => HyperliquidUrls.infoUrl(isTestnet: isTestnet);

  /// The base exchange URL for this transport.
  String get exchangeUrl => HyperliquidUrls.exchangeUrl(isTestnet: isTestnet);

  /// Send a POST request to the Info endpoint.
  ///
  /// [payload] is the JSON body to send.
  /// Returns the decoded JSON response.
  Future<dynamic> postInfo(Map<String, dynamic> payload) async {
    return _post(infoUrl, payload);
  }

  /// Send a POST request to the Exchange endpoint.
  ///
  /// [payload] is the JSON body to send.
  /// Returns the decoded JSON response.
  Future<dynamic> postExchange(Map<String, dynamic> payload) async {
    return _post(exchangeUrl, payload);
  }

  Future<dynamic> _post(String url, Map<String, dynamic> payload) async {
    final response = await _client.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw HyperliquidApiException(
        statusCode: response.statusCode,
        message: '${response.statusCode} ${response.reasonPhrase}',
        body: response.body,
      );
    }

    return jsonDecode(response.body);
  }

  /// Close the underlying HTTP client.
  ///
  /// After calling this, no further requests can be made.
  void close() {
    _client.close();
  }
}
