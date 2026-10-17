import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fun_painting/presentation/common/localization/app_language.dart';
import 'package:fun_painting/presentation/common/localization/translations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppLanguage.current.value = AppLanguage.fallbackCode;
  });

  group('choosing the language', () {
    test('follows a supported phone language, whatever the region', () {
      expect(AppLanguage.resolveDevice(const Locale('ar', 'EG')), 'ar');
      expect(AppLanguage.resolveDevice(const Locale('de', 'DE')), 'de');
      expect(AppLanguage.resolveDevice(const Locale('pt', 'BR')), 'pt');
    });

    test('falls back to English when the phone language is not supported', () {
      expect(AppLanguage.resolveDevice(const Locale('ja')), 'en');
      expect(AppLanguage.resolveDevice(const Locale('zh', 'CN')), 'en');
    });

    test('older Android reports Indonesian as "in"', () {
      expect(AppLanguage.resolveDevice(const Locale('in')), 'id');
    });

    test('load() uses the phone language when nothing is saved', () async {
      await AppLanguage.load();
      // flutter_test reports en_US, which we support as English.
      expect(AppLanguage.current.value, 'en');
    });

    test('a saved choice wins over the phone language', () async {
      SharedPreferences.setMockInitialValues({'app_language': 'fr'});
      await AppLanguage.load();
      expect(AppLanguage.current.value, 'fr');
    });

    test('a saved unknown code is ignored', () async {
      SharedPreferences.setMockInitialValues({'app_language': 'klingon'});
      await AppLanguage.load();
      expect(AppLanguage.current.value, 'en');
    });

    test('select() switches and remembers the language', () async {
      await AppLanguage.select('tr');
      expect(AppLanguage.current.value, 'tr');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_language'), 'tr');
    });

    test('select() ignores codes we do not support', () async {
      await AppLanguage.select('klingon');
      expect(AppLanguage.current.value, 'en');
    });
  });

  group('translations', () {
    test('every language has exactly the English keys', () {
      final english = kTranslations['en']!.keys.toSet();
      for (final option in AppLanguage.options) {
        final table = kTranslations[option.code];
        expect(table, isNotNull, reason: 'missing table for ${option.code}');
        expect(
          table!.keys.toSet(),
          equals(english),
          reason: 'keys differ for ${option.code}',
        );
      }
    });

    test('no translated text is empty', () {
      for (final entry in kTranslations.entries) {
        for (final value in entry.value.values) {
          expect(value.trim(), isNotEmpty, reason: entry.key);
        }
      }
    });

    test('each language option has a table and unique codes', () {
      final codes = AppLanguage.options.map((o) => o.code).toList();
      expect(codes.toSet().length, codes.length);
      for (final code in codes) {
        expect(kTranslations.containsKey(code), isTrue, reason: code);
      }
    });

    test('tr() shows the text of the current language', () {
      AppLanguage.current.value = 'fr';
      expect(tr('play'), 'JOUER');
      AppLanguage.current.value = 'en';
      expect(tr('play'), 'PLAY');
    });

    test('tr() fills {placeholders}', () {
      AppLanguage.current.value = 'en';
      expect(tr('stamp_size', {'size': '12'}), 'Stamp Size: 12');
      AppLanguage.current.value = 'de';
      expect(tr('stamp_size', {'size': '12'}), 'Stempelgröße: 12');
    });

    test('tr() falls back to the key when a key does not exist', () {
      expect(tr('no_such_key_anywhere'), 'no_such_key_anywhere');
    });

    test('trName() translates world and brush names, keeps unknown ones', () {
      AppLanguage.current.value = 'ar';
      expect(trName('Pictures'), 'الصور');
      expect(trName('Thin brush'), 'فرشاة رفيعة');
      expect(trName('Mystery'), 'Mystery');
    });

    test('Arabic is marked right-to-left, the others are not', () {
      for (final option in AppLanguage.options) {
        expect(option.rtl, option.code == 'ar', reason: option.code);
      }
    });
  });
}
