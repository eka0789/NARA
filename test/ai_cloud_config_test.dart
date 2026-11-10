import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nara/core/ai/gemini_service.dart';
import 'package:nara/core/constants/app_constants.dart';
import 'package:nara/core/providers/core_providers.dart';
import 'package:nara/core/storage/local_keys.dart';
import 'package:nara/core/storage/local_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records the request a [GeminiService] makes and replies with [reply].
MockClient _client(
  void Function(http.Request request) onRequest,
  http.Response Function(http.Request request) reply,
) {
  return MockClient((request) async {
    onRequest(request);
    return reply(request);
  });
}

http.Response _geminiOk(String text) => http.Response(
      jsonEncode({
        'candidates': [
          {
            'content': {
              'parts': [
                {'text': text},
              ],
            },
          },
        ],
      }),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

http.Response _openAiOk(String text) => http.Response(
      jsonEncode({
        'choices': [
          {
            'message': {'role': 'assistant', 'content': text},
          },
        ],
      }),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

Future<String> _reply(GeminiService service) => service.generateReply(
      systemPrompt: 'You are NARA.',
      userMessage: 'halo',
      history: const [],
    );

void main() {
  group('GeminiService request configuration', () {
    test('default config hits the built-in Gemini endpoint and model', () async {
      late http.Request captured;
      final service = GeminiService(
        client: _client(
          (r) => captured = r,
          (_) => _geminiOk('halo ada'),
        ),
        apiKey: 'build-key',
      );

      expect(await _reply(service), 'halo ada');
      expect(
        captured.url.toString(),
        '${AppConstants.geminiBaseUrl}/'
        '${AppConstants.geminiModel}:generateContent',
      );
      expect(captured.headers['x-goog-api-key'], 'build-key');
      expect(captured.headers['authorization'], isNull);
    });

    test('custom baseUrl + model + key override every default', () async {
      late http.Request captured;
      final service = GeminiService(
        client: _client((r) => captured = r, (_) => _geminiOk('ok')),
        apiKey: 'custom-key',
        baseUrl: 'https://relay.example.com/v1beta/models',
        model: 'my-relay-model',
      );

      await _reply(service);
      expect(
        captured.url.toString(),
        'https://relay.example.com/v1beta/models/my-relay-model:generateContent',
      );
      expect(captured.headers['x-goog-api-key'], 'custom-key');
    });

    test('trailing slash on baseUrl does not produce double slashes', () async {
      late http.Request captured;
      final service = GeminiService(
        client: _client((r) => captured = r, (_) => _geminiOk('ok')),
        apiKey: 'k',
        baseUrl: 'https://relay.example.com/v1beta/models/',
        model: 'm',
      );

      await _reply(service);
      expect(
        captured.url.toString(),
        'https://relay.example.com/v1beta/models/m:generateContent',
      );
    });
  });

  group('OpenAI wire format', () {
    test('posts chat/completions with Bearer auth and model+messages body', () async {
      late http.Request captured;
      final service = GeminiService(
        client: _client((r) => captured = r, (_) => _openAiOk('jawaban')),
        apiKey: 'sk-test',
        baseUrl: 'https://api.openai.com/v1',
        model: 'gpt-4o-mini',
        apiStyle: AiApiStyle.openai,
      );

      expect(await _reply(service), 'jawaban');
      expect(captured.url.toString(), 'https://api.openai.com/v1/chat/completions');
      expect(captured.headers['Authorization'], 'Bearer sk-test');
      expect(captured.headers['x-goog-api-key'], isNull);

      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['model'], 'gpt-4o-mini');
      final messages = body['messages'] as List;
      expect((messages.first as Map)['role'], 'system');
      expect((messages.last as Map)['role'], 'user');
      expect((messages.last as Map)['content'], 'halo');
      expect(body['temperature'], 0.7);
    });

    test('base URL already ending in /chat/completions is not doubled', () async {
      late http.Request captured;
      final service = GeminiService(
        client: _client((r) => captured = r, (_) => _openAiOk('ok')),
        apiKey: 'k',
        baseUrl: 'https://router.example.com/v1/chat/completions',
        model: 'm',
        apiStyle: AiApiStyle.openai,
      );

      await _reply(service);
      expect(
        captured.url.toString(),
        'https://router.example.com/v1/chat/completions',
      );
    });

    test('history maps to user/assistant roles', () async {
      late http.Request captured;
      final service = GeminiService(
        client: _client((r) => captured = r, (_) => _openAiOk('ok')),
        apiKey: 'k',
        baseUrl: 'https://api.example.com/v1',
        model: 'm',
        apiStyle: AiApiStyle.openai,
      );

      await service.generateReply(
        systemPrompt: 'sys',
        userMessage: 'pertanyaan',
        history: const [],
      );
      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      final roles = [
        for (final m in body['messages'] as List) (m as Map)['role'],
      ];
      expect(roles, ['system', 'user']);
    });

    test('401 maps to invalid-key, 429 to quota', () async {
      final unauthorized = GeminiService(
        client: _client((_) {}, (_) => http.Response('nope', 401)),
        apiKey: 'bad',
        baseUrl: 'https://api.example.com/v1',
        model: 'm',
        apiStyle: AiApiStyle.openai,
      );
      await expectLater(
        _reply(unauthorized),
        throwsA(
          isA<AiException>().having((e) => e.code, 'code', 'invalid-key'),
        ),
      );

      final limited = GeminiService(
        client: _client((_) {}, (_) => http.Response('slow down', 429)),
        apiKey: 'k',
        baseUrl: 'https://api.example.com/v1',
        model: 'm',
        apiStyle: AiApiStyle.openai,
      );
      await expectLater(
        _reply(limited),
        throwsA(isA<AiException>().having((e) => e.code, 'code', 'quota')),
      );
    });

    test('missing/empty choices maps to empty', () async {
      final service = GeminiService(
        client: _client(
          (_) {},
          (_) => http.Response(
            jsonEncode({'choices': []}),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
        apiKey: 'k',
        baseUrl: 'https://api.example.com/v1',
        model: 'm',
        apiStyle: AiApiStyle.openai,
      );
      await expectLater(
        _reply(service),
        throwsA(isA<AiException>().having((e) => e.code, 'code', 'empty')),
      );
    });
  });

  group('AI config providers', () {
    test('fall back to build defaults when prefs are empty', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          localStoreProvider.overrideWithValue(LocalStore(prefs)),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(aiBaseUrlProvider), AppConstants.geminiBaseUrl);
      expect(container.read(aiModelProvider), AppConstants.geminiModel);
      expect(container.read(aiApiStyleProvider), AiApiStyle.gemini);
      expect(container.read(aiKeyProvider), AppConstants.geminiApiKey);

      final service = container.read(geminiServiceProvider);
      expect(service.baseUrl, AppConstants.geminiBaseUrl);
      expect(service.model, AppConstants.geminiModel);
      expect(service.apiStyle, AiApiStyle.gemini);
    });

    test('overrides persist and rebuild the service', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = LocalStore(prefs);
      final container = ProviderContainer(
        overrides: [localStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);

      container.read(aiBaseUrlProvider.notifier).set('https://my.host/v1');
      container.read(aiModelProvider.notifier).set('llama-3');
      container.read(aiApiStyleProvider.notifier).set(AiApiStyle.openai);

      expect(store.readString(LocalKeys.aiBaseUrl), 'https://my.host/v1');
      expect(store.readString(LocalKeys.aiModel), 'llama-3');
      expect(store.readString(LocalKeys.aiApiStyle), 'openai');

      final service = container.read(geminiServiceProvider);
      expect(service.baseUrl, 'https://my.host/v1');
      expect(service.model, 'llama-3');
      expect(service.apiStyle, AiApiStyle.openai);

      // Reset-to-default: clearing the value restores the build default.
      container.read(aiBaseUrlProvider.notifier).set(null);
      container.read(aiModelProvider.notifier).set(null);
      expect(container.read(aiBaseUrlProvider), AppConstants.geminiBaseUrl);
      expect(container.read(aiModelProvider), AppConstants.geminiModel);
      expect(store.readString(LocalKeys.aiBaseUrl), isNull);
    });
  });
}
