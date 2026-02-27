import 'dart:async';

import 'package:http/http.dart' as http;

/// Exception thrown by [WebFetchService] when URL fetching or parsing fails.
class WebFetchException implements Exception {
  const WebFetchException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Fetches web pages and extracts plain text suitable for model prompts.
class WebFetchService {
  /// Maximum characters returned to keep prompts within context limits.
  static const int maxChars = 3000;

  /// Fetches [url], strips HTML, normalizes whitespace, and truncates output.
  Future<String> fetchAndExtract(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !uri.hasScheme ||
        (!uri.isScheme('http') && !uri.isScheme('https'))) {
      throw const WebFetchException(
        'Invalid URL. Please enter a valid web address.',
      );
    }

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw WebFetchException(
          'Failed to load page (HTTP ${response.statusCode}).',
        );
      }

      final extracted = response.body
          .replaceAll(
            RegExp(
              r'<script[^>]*>[\s\S]*?</script>',
              caseSensitive: false,
            ),
            '',
          )
          .replaceAll(
            RegExp(
              r'<style[^>]*>[\s\S]*?</style>',
              caseSensitive: false,
            ),
            '',
          )
          .replaceAll(RegExp(r'<[^>]+>'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      if (extracted.isEmpty) {
        throw const WebFetchException('No text content found on this page.');
      }

      if (extracted.length <= maxChars) {
        return extracted;
      }
      return extracted.substring(0, maxChars);
    } on http.ClientException catch (error) {
      throw WebFetchException('Network error: ${error.message}');
    } on TimeoutException {
      throw const WebFetchException('Request timed out. Please try again.');
    }
  }
}
