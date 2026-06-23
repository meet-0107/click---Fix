import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'llm_config.dart';

/// Service class to communicate with Nvidia Multimodal LLM endpoints.
class LlmService {
  /// Diagnoses the appliance issue from the captured image.
  /// Returns a Map with the structured diagnosis results.
  static Future<Map<String, dynamic>> diagnoseImage(XFile imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    // Determine MIME type
    final mimeType = imageFile.name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
    final imageUrl = 'data:$mimeType;base64,$base64Image';

    final url = Uri.parse('${LlmConfig.baseUrl}/chat/completions');

    var model = LlmConfig.modelName;
    final lowerModel = model.toLowerCase();
    if (!lowerModel.contains('vision') &&
        !lowerModel.contains('vl') &&
        !lowerModel.contains('vila') &&
        !lowerModel.contains('image')) {
      debugPrint("Warning: Configured model '$model' is not a known vision model. Falling back to 'meta/llama-3.2-11b-vision-instruct' for multimodal compatibility.");
      model = "meta/llama-3.2-11b-vision-instruct";
    }

    const prompt = """
Analyze the attached image of a broken home appliance, control panel, or screen showing an error code.
Your goal is to identify the appliance, diagnose the issue, explain any error codes, and provide step-by-step DIY repair instructions if possible.

You must respond ONLY with a valid JSON object in the following format:
{
  "appliance": "Appliance Type (e.g., Washing Machine, TV, AC, Laptop, Mobile, Fan, Remote, or other)",
  "issue": "Brief description of the problem (e.g., Not draining, No power, Overheating, Screen flickering)",
  "errorCode": "Any detected error code (e.g., E18, E15, F1, or 'None' if not visible)",
  "summary": "A concise explanation of the problem based on the visual evidence.",
  "confidence": 0.85,
  "customDiySteps": [
    "Step 1: Check power...",
    "Step 2: Clean filter...",
    "Step 3: Test appliance..."
  ]
}

Ensure the response is strictly JSON, without markdown formatting blocks (do not put ```json ... ``` around it), just the raw JSON object.
""";

    final headers = {
      'Authorization': 'Bearer ${LlmConfig.apiKey}',
      'Content-Type': 'application/json',
    };

    final payload = {
      'model': model,
      'messages': [
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': prompt},
            {
              'type': 'image_url',
              'image_url': {'url': imageUrl}
            }
          ]
        }
      ],
      'max_tokens': 1000
    };

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final content = jsonResponse['choices'][0]['message']['content'] as String;

      // Clean the content in case the model wraps the JSON in markdown code blocks
      var cleanContent = content.trim();
      if (cleanContent.startsWith('```')) {
        final lines = cleanContent.split('\n');
        if (lines.isNotEmpty && (lines.first.startsWith('```json') || lines.first.startsWith('```'))) {
          lines.removeAt(0);
        }
        if (lines.isNotEmpty && lines.last.startsWith('```')) {
          lines.removeLast();
        }
        cleanContent = lines.join('\n').trim();
      }

      debugPrint("Centralized LLM Response Content: $cleanContent");
      return jsonDecode(cleanContent) as Map<String, dynamic>;
    } else {
      throw Exception('LLM diagnosis failed with status ${response.statusCode}: ${response.body}');
    }
  }

  /// Generates a step-by-step repair guide for a given appliance and issue using the LLM.
  static Future<List<String>> generateGuide(String appliance, String issue) async {
    final url = Uri.parse('${LlmConfig.baseUrl}/chat/completions');

    final prompt = """
Generate a detailed guide with exactly 10 step-by-step DIY repair instructions for the following problem:
Appliance: $appliance
Problem: $issue

You must respond ONLY with a valid JSON object containing a list of exactly 10 steps in the following format:
{
  "steps": [
    "Step 1: Description...",
    "Step 2: Description...",
    "Step 3: Description...",
    "Step 4: Description...",
    "Step 5: Description...",
    "Step 6: Description...",
    "Step 7: Description...",
    "Step 8: Description...",
    "Step 9: Description...",
    "Step 10: Description..."
  ]
}

Ensure the response is strictly JSON, without markdown formatting blocks (do not put ```json ... ``` around it), just the raw JSON object.
""";

    final headers = {
      'Authorization': 'Bearer ${LlmConfig.apiKey}',
      'Content-Type': 'application/json',
    };

    final payload = {
      'model': LlmConfig.modelName,
      'messages': [
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': prompt}
          ]
        }
      ],
      'max_tokens': 1000
    };

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final content = jsonResponse['choices'][0]['message']['content'] as String;

      var cleanContent = content.trim();
      if (cleanContent.startsWith('```')) {
        final lines = cleanContent.split('\n');
        if (lines.isNotEmpty && (lines.first.startsWith('```json') || lines.first.startsWith('```'))) {
          lines.removeAt(0);
        }
        if (lines.isNotEmpty && lines.last.startsWith('```')) {
          lines.removeLast();
        }
        cleanContent = lines.join('\n').trim();
      }

      final parsed = jsonDecode(cleanContent) as Map<String, dynamic>;
      final List<dynamic> rawSteps = parsed['steps'] ?? [];
      return rawSteps.map((s) => s.toString()).toList();
    } else {
      throw Exception('Failed to generate guide: ${response.statusCode} - ${response.body}');
    }
  }
}
