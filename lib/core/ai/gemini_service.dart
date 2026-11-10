import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/app_constants.dart';
import '../models/chat_message.dart';

/// Wire format for cloud AI calls.
enum AiApiStyle {
  /// Gemini REST: `<base>/<model>:generateContent`, `x-goog-api-key` header.
  gemini,

  /// OpenAI chat completions: `<base>/chat/completions`, `Authorization: Bearer`.
  /// Covers OpenAI, OpenRouter, DeepSeek, Ollama, LM Studio and friends.
  openai;

  /// Parses a stored style name; unknown/missing values fall back to [AiApiStyle.gemini].
  static AiApiStyle fromName(String? name) =>
      AiApiStyle.values.asNameMap()[name] ?? AiApiStyle.gemini;
}

/// Cloud AI tier of the hybrid strategy.
///
/// Talks to any compatible endpoint: the built-in Gemini default, your own
/// relay/proxy, or an OpenAI-compatible provider — base URL, API key and
/// model are configurable at build time (`--dart-define=NARA_GEMINI_*`) or
/// at runtime from the Profile → AI Cloud sheet.
///
/// The API key is sent to whatever base URL is configured: for hardened
/// production deployments, proxy through a Cloud Function so the key never
/// lives on clients — see docs/SECURITY.md.
class GeminiService {
  GeminiService({
    http.Client? client,
    String? apiKey,
    String? baseUrl,
    String? model,
    AiApiStyle? apiStyle,
  })  : _client = client ?? http.Client(),
        _apiKey = apiKey ?? AppConstants.geminiApiKey,
        _baseUrl = _trimSlashes(baseUrl ?? AppConstants.geminiBaseUrl),
        _model = (model ?? AppConstants.geminiModel).trim(),
        _apiStyle = apiStyle ?? AiApiStyle.gemini;

  static String _trimSlashes(String value) {
    var trimmed = value.trim();
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  final http.Client _client;
  final String? _apiKey;
  final String _baseUrl;
  final String _model;
  final AiApiStyle _apiStyle;

  /// Active configuration (exposed so UI/tests can introspect overrides).
  String get baseUrl => _baseUrl;
  String get model => _model;
  AiApiStyle get apiStyle => _apiStyle;

  bool get isConfigured => (_apiKey ?? '').trim().isNotEmpty;

  /// Generates an assistant reply for [userMessage] with [history] context.
  Future<String> generateReply({
    required String systemPrompt,
    required String userMessage,
    required List<ChatMessage> history,
  }) async {
    final key = (_apiKey ?? '').trim();
    if (key.isEmpty) throw const AiException('not-configured');

    final recent = [
      for (final message in history)
        if (message.text.trim().isNotEmpty) message,
    ];
    final trimmed = recent.length > AppConstants.aiHistoryTurns
        ? recent.sublist(recent.length - AppConstants.aiHistoryTurns)
        : recent;

    final uri = switch (_apiStyle) {
      AiApiStyle.gemini => Uri.parse('$_baseUrl/$_model:generateContent'),
      AiApiStyle.openai => Uri.parse(
          _baseUrl.endsWith('/chat/completions')
              ? _baseUrl
              : '$_baseUrl/chat/completions',
        ),
    };
    // Keys go in headers, not the URL: URLs routinely end up in
    // proxy/server logs, headers do not. (x-goog-api-key is the documented
    // Gemini REST auth header; Bearer is the OpenAI standard.)
    final headers = switch (_apiStyle) {
      AiApiStyle.gemini => {
          'Content-Type': 'application/json',
          'x-goog-api-key': key,
        },
      AiApiStyle.openai => {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $key',
        },
    };
    final body = switch (_apiStyle) {
      AiApiStyle.gemini => _geminiBody(systemPrompt, trimmed, userMessage),
      AiApiStyle.openai => _openAiBody(systemPrompt, trimmed, userMessage),
    };

    http.Response response;
    try {
      response = await _client
          .post(uri, headers: headers, body: body)
          .timeout(AppConstants.aiTimeout);
    } on TimeoutException {
      throw const AiException('network');
    } on http.ClientException {
      throw const AiException('network');
    }

    switch (response.statusCode) {
      case 200:
        break;
      case 400:
      case 401:
      case 403:
        throw const AiException('invalid-key');
      case 404:
        // Wrong base URL or model name — both user-configurable.
        throw const AiException('invalid-endpoint');
      case 429:
        throw const AiException('quota');
      default:
        throw const AiException('bad-response');
    }

    return _parseReply(response);
  }

  String _geminiBody(
    String systemPrompt,
    List<ChatMessage> trimmed,
    String userMessage,
  ) {
    return jsonEncode({
      'system_instruction': {
        'parts': [
          {'text': systemPrompt},
        ],
      },
      'contents': [
        for (final message in trimmed)
          {
            'role': message.isUser ? 'user' : 'model',
            'parts': [
              {'text': message.text},
            ],
          },
        {
          'role': 'user',
          'parts': [
            {'text': userMessage},
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.7,
        'topP': 0.9,
        'maxOutputTokens': 600,
      },
      'safetySettings': [
        {
          'category': 'HARM_CATEGORY_HARASSMENT',
          'threshold': 'BLOCK_ONLY_HIGH',
        },
        {
          'category': 'HARM_CATEGORY_HATE_SPEECH',
          'threshold': 'BLOCK_ONLY_HIGH',
        },
      ],
    });
  }

  String _openAiBody(
    String systemPrompt,
    List<ChatMessage> trimmed,
    String userMessage,
  ) {
    return jsonEncode({
      'model': _model,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        for (final message in trimmed)
          {
            'role': message.isUser ? 'user' : 'assistant',
            'content': message.text,
          },
        {'role': 'user', 'content': userMessage},
      ],
      'temperature': 0.7,
      'top_p': 0.9,
      'max_tokens': 600,
    });
  }

  String _parseReply(http.Response response) {
    try {
      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final text = switch (_apiStyle) {
        AiApiStyle.gemini => _geminiText(data),
        AiApiStyle.openai => _openAiText(data),
      };
      if (text.isEmpty) throw const AiException('empty');
      return text;
    } on AiException {
      rethrow;
    } on FormatException {
      throw const AiException('bad-response');
    } on TypeError {
      throw const AiException('bad-response');
    }
  }

  String _geminiText(Map<String, dynamic> data) {
    final candidates = data['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) return '';
    final content =
        (candidates.first as Map<String, dynamic>)['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List?;
    return [
      if (parts != null)
        for (final part in parts)
          if (part is Map && part['text'] is String) part['text'] as String,
    ].join('\n').trim();
  }

  String _openAiText(Map<String, dynamic> data) {
    final choices = data['choices'] as List?;
    if (choices == null || choices.isEmpty) return '';
    final message = (choices.first as Map)['message'] as Map<String, dynamic>?;
    final content = message?['content'];
    return content is String ? content.trim() : '';
  }
}

/// Cloud AI failure codes, mapped for presentation by the chat feature.
class AiException implements Exception {
  const AiException(this.code);

  /// not-configured | invalid-key | invalid-endpoint | quota | network | bad-response | empty
  final String code;

  @override
  String toString() => 'AiException($code)';
}
