// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';
import 'package:test/test.dart';

void main() {
  final plugin = Plugin.example();

  group('Plugin', () {
    group('example', () {
      test('should add itself the the host scope', () {
        expect(plugin.scope.plugins, contains(plugin));
      });
    });

    group('dispose', () {
      test('should remove the plugin from its scope', () {
        final plugin = Plugin.example();
        expect(plugin.scope.plugins, contains(plugin));
        plugin.dispose();
        expect(plugin.scope.plugins, isNot(contains(plugin)));
      });
    });

    group('should throw', () {
      test('test when another plugin with the same key already exists in scope',
          () {
        // Create a scope
        final scope = Scope.example();
        // Create two blue prints with the same key
        final bluePrint0 = PluginBluePrint.example.bluePrint;
        final bluePrint1 = PluginBluePrint.example.bluePrint;

        // Instantiate the first plugin
        bluePrint0.instantiate(scope: scope);

        // Instantiating another plugin with the same key should throw
        expect(
          () => bluePrint1.instantiate(scope: scope),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Another plugin with key examplePlugin is added.'),
            ),
          ),
        );
      });
    });
  });
}
