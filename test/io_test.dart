@TestOn('vm')
library;

import 'dart:io';

import 'package:oushodh/oushodh.dart';
import 'package:test/test.dart';

Future<String> runWithEnv(Map<String, String> environment) async {
  final result = await Process.run(Platform.resolvedExecutable, [
    'run',
    'test/fixtures/env_key.dart',
  ], environment: environment);

  return (result.stdout as String).trim();
}

void main() {
  test('the key comes from OUSHODH_API_KEY', () async {
    expect(await runWithEnv({'OUSHODH_API_KEY': 'oush_test_env'}), 'ok');
  });

  test('with no key anywhere, construction fails with a clear error', () async {
    final output = await runWithEnv({'OUSHODH_API_KEY': ''});

    expect(output, contains('No API key'));
  });

  test('version matches pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(pubspec, contains('\nversion: $version\n'));
  });
}
