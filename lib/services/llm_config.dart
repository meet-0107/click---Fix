import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Centralized configuration class for the LLM API.
/// Reads settings from `assets/.env` at runtime.
class LlmConfig {
  static String? _baseUrl;
  static String? _apiKey;
  static String? _modelName;

  static String get baseUrl => _baseUrl ?? 'https://integrate.api.nvidia.com/v1';
  static String get apiKey => _apiKey ?? '';
  static String get modelName => _modelName ?? 'meta/llama-3.2-11b-vision-instruct';

  /// Loads configuration from `assets/.env`
  static Future<void> load() async {
    try {
      final content = await rootBundle.loadString('assets/.env');
      final lines = content.split('\n');
      for (var line in lines) {
        line = line.trim();
        if (line.isEmpty || line.startsWith('#')) continue;
        final index = line.indexOf('=');
        if (index != -1) {
          final key = line.substring(0, index).trim();
          final value = line.substring(index + 1).trim();
          if (key == 'LLM_BASE_URL' || key == 'LLM_ENDPOINT') {
            var val = value;
            if (val.endsWith('/chat/completions')) {
              val = val.substring(0, val.length - '/chat/completions'.length);
            }
            _baseUrl = val;
          } else if (key == 'LLM_API_KEY') {
            _apiKey = value;
          } else if (key == 'LLM_MODEL_NAME' || key == 'LLM_MODEL') {
            _modelName = value;
          }
        }
      }
      debugPrint('Loaded LLM Config: modelName=$modelName, baseUrl=$baseUrl, keyLength=${apiKey.length}');
    } catch (e) {
      debugPrint('Error loading .env config: $e');
    }
  }
}
