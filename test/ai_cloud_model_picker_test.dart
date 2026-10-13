import 'package:shepherd/src/tools/presentation/commands/ai_cloud_model_picker.dart';
import 'package:test/test.dart';

void main() {
  group('cloudProviderForChoice', () {
    test('maps option numbers and provider names, not model names', () {
      expect(cloudProviderForChoice('4'), 'gemini');
      expect(cloudProviderForChoice(' Gemini '), 'gemini');
      expect(cloudProviderForChoice('claude'), 'anthropic');
      expect(cloudProviderForChoice('2'), 'openai');
      expect(cloudProviderForChoice('gemini-3.8-flash'), isNull);
      expect(cloudProviderForChoice('1'), isNull);
    });
  });

  group('buildCloudModelList', () {
    test(
        'puts what the API reports first, newest on top, without non-chat '
        'models', () {
      final list = buildCloudModelList(
        providerId: 'gemini',
        online: [
          'gemini-2.5-flash',
          'gemini-3.8-flash',
          'gemini-3.8-flash-tts',
          'gemini-3.8-flash-image',
        ],
        saved: ['meu-modelo'],
        current: 'gemini-2.5-flash',
      );
      expect(list.first, 'gemini-3.8-flash');
      expect(list, isNot(contains('gemini-3.8-flash-tts')));
      expect(list, isNot(contains('gemini-3.8-flash-image')));
      expect(list, contains('meu-modelo'));
      expect(list.where((m) => m == 'gemini-2.5-flash'), hasLength(1));
    });

    test('falls back to the built-in list and always has the current model',
        () {
      final list = buildCloudModelList(
          providerId: 'gemini', online: [], saved: [], current: 'custom-x');
      expect(list, contains('gemini-3.8-flash'));
      expect(list, contains('custom-x'));
    });
  });

  test('versions sort as numbers, newest first', () {
    final list = buildCloudModelList(
        providerId: 'gemini',
        online: ['gemini-3.8-flash', 'gemini-3.10-flash', 'gemini-3.9-flash'],
        saved: [],
        current: 'x');
    expect(list.take(3),
        ['gemini-3.10-flash', 'gemini-3.9-flash', 'gemini-3.8-flash']);
  });

  group('promptCloudModelSelection', () {
    Future<String> pick(List<String> answers,
        {List<String> online = const [
          'gemini-3.8-flash',
          'gemini-2.5-flash'
        ]}) {
      final it = answers.iterator;
      return promptCloudModelSelection(
        providerId: 'gemini',
        providerLabel: 'Google (Gemini)',
        apiKey: 'k',
        currentModel: 'gemini-2.5-flash',
        savedModels: const [],
        fetchOnline: () async => online,
        readLine: () => it.moveNext() ? it.current : null,
      );
    }

    test('picks by number', () async {
      expect(await pick(['1']), 'gemini-3.8-flash');
    });
    test('Enter keeps the current model', () async {
      expect(await pick(['']), 'gemini-2.5-flash');
    });
    test('an out-of-range number keeps the current model', () async {
      expect(await pick(['99']), 'gemini-2.5-flash');
    });
    test('m lets the user type a name', () async {
      expect(await pick(['m', 'outro-modelo']), 'outro-modelo');
    });
  });
}
