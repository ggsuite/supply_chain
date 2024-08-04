// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';
import 'package:test/test.dart';

void main() {
  final customizer = Customizer.example();

  group('Customizer', () {
    group('example', () {
      test('should add itself the the host scope', () {
        expect(customizer.scope.customizers, contains(customizer));
      });
    });

    group('dispose', () {
      test('should remove the customizer from its scope', () {
        final customizer = Customizer.example();
        expect(customizer.scope.customizers, contains(customizer));
        customizer.dispose();
        expect(customizer.scope.customizers, isNot(contains(customizer)));
      });
    });

    group('should throw', () {
      test(
          'test when another customizer with the same key '
          'already exists in scope', () {
        // Create a scope
        final scope = Scope.example();
        // Create two blue prints with the same key
        final bluePrint0 = CustomizerBluePrint.example.bluePrint;
        final bluePrint1 = CustomizerBluePrint.example.bluePrint;

        // Instantiate the first customizer
        bluePrint0.instantiate(scope: scope);

        // Instantiating another customizer with the same key should throw
        expect(
          () => bluePrint1.instantiate(scope: scope),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains(
                'Another customizer with key exampleCustomizer is added.',
              ),
            ),
          ),
        );
      });
    });
  });
}
