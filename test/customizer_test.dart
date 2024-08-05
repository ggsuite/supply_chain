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

      test('should be applied to nodes added after instantiation', () {
        final customizer = ExampleCustomizerBluePrint.example;

        // Make sure, example customizer is added to the scope
        final scope = customizer.scope;
        expect(scope.customizers.first, customizer);

        // The customizer applied inserts
        final hostA = scope.findNode<int>('hostA')!;
        final hostB = scope.findNode<int>('hostB')!;
        final hostC = scope.findNode<int>('hostC')!;

        expect(hostA.inserts, hasLength(2));
        expect(hostB.inserts, hasLength(3));
        expect(hostC.inserts, hasLength(3));

        // Let's add two more nodes to the scopeA and scopeB
        final scopeA = scope.findScope('a')!;
        final scopeB = scope.findScope('b')!;

        final hostA1 =
            const NodeBluePrint<int>(key: 'hostA1', initialProduct: 11)
                .instantiate(scope: scopeA);

        final hostB1 =
            const NodeBluePrint<int>(key: 'hostB1', initialProduct: 12)
                .instantiate(scope: scopeB);

        // The customizers are applied to the newly added nodes
        expect(hostA1.inserts, hasLength(2));
        expect(hostB1.inserts, hasLength(3));
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
