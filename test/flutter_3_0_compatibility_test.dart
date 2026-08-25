import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Flutter 3.0 compatibility policy', () {
    test('pubspecs declare Dart 2.17 and Flutter 3.0 minimums', () {
      for (final path in ['pubspec.yaml', 'example/pubspec.yaml']) {
        final pubspec = File(path).readAsStringSync();

        expect(
          pubspec,
          contains("sdk: '>=2.17.0 <4.0.0'"),
          reason: '$path must remain installable with Dart 2.17.0.',
        );
        expect(
          pubspec,
          contains("flutter: '>=3.0.0'"),
          reason: '$path must document the real minimum Flutter version.',
        );
      }
    });

    test('sources avoid APIs introduced after Flutter 3.0', () {
      const sourceRoots = [
        'lib',
        'example/lib',
        'test',
        'example/test',
        'tool'
      ];
      final unsupportedPatterns = <RegExp, String>{
        RegExp(r'\.withValues\s*\('):
            'Color.withValues was added after Flutter 3.0',
        RegExp(r'\bFilledButton\b'): 'FilledButton was added after Flutter 3.0',
        RegExp(r'\bPopScope\s*\('): 'PopScope was added after Flutter 3.0',
        RegExp(r'\bonPopInvoked\w*\b'):
            'onPopInvoked was added after Flutter 3.0',
        RegExp(r'\bcolor\.(?:a|r|g|b)\b'):
            'floating-point Color channels were added after Flutter 3.0',
        RegExp(
          r'TestDefaultBinaryMessengerBinding\.instance\s*\.defaultBinaryMessenger',
        ): 'TestDefaultBinaryMessengerBinding.instance is nullable in Flutter 3.0',
      };

      final violations = <String>[];
      for (final root in sourceRoots) {
        final directory = Directory(root);
        if (!directory.existsSync()) continue;

        for (final entity in directory.listSync(recursive: true)) {
          if (entity is! File || !entity.path.endsWith('.dart')) continue;
          if (entity.path.endsWith('flutter_3_0_compatibility_test.dart')) {
            continue;
          }

          final source = entity.readAsStringSync();
          for (final entry in unsupportedPatterns.entries) {
            if (entry.key.hasMatch(source)) {
              violations.add('${entity.path}: ${entry.value}');
            }
          }
        }
      }

      expect(violations, isEmpty, reason: violations.join('\n'));
    });
  });
}
