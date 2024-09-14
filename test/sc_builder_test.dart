// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';
import 'package:test/test.dart';

void main() {
  final builder = ScBuilder.example();

  group('ScBuilder', () {
    group('example', () {
      test('should add itself the the host scope', () {
        expect(builder.scope.builders, contains(builder));
      });

      test('should be applied to nodes added after instantiation', () {
        final builder = ExampleScBuilderBluePrint.example;

        // Make sure, example builder is added to the scope
        final scope = builder.scope;
        expect(scope.builders.first, builder);

        // The builder applied inserts
        final hostA = scope.findNode<int>('hostA')!;
        final hostB = scope.findNode<int>('hostB')!;
        final hostC = scope.findNode<int>('hostC')!;

        expect(hostA.inserts, hasLength(2));
        expect(hostB.inserts, hasLength(3));
        expect(hostC.inserts, hasLength(3));

        // Let's add two more nodes to the scopeA and scopeB
        final scopeA = scope.findChildScope('a')!;
        final scopeB = scope.findChildScope('b')!;

        final hostA1 =
            const NodeBluePrint<int>(key: 'hostA1', initialProduct: 11)
                .instantiate(scope: scopeA);

        final hostB1 =
            const NodeBluePrint<int>(key: 'hostB1', initialProduct: 12)
                .instantiate(scope: scopeB);

        // The builders are applied to the newly added nodes
        expect(hostA1.inserts, hasLength(2));
        expect(hostB1.inserts, hasLength(3));
      });
    });

    group('dispose', () {
      test('should remove the builder from its scope', () {
        final builder = ScBuilder.example();
        expect(builder.scope.builders, contains(builder));
        builder.dispose();
        expect(builder.scope.builders, isNot(contains(builder)));
      });
    });

    group('should throw', () {
      test(
          'test when another builder with the same key '
          'already exists in scope', () {
        // Create a scope
        final scope = Scope.example();
        // Create two blue prints with the same key
        final bluePrint0 = ScBuilderBluePrint.example.bluePrint;
        final bluePrint1 = ScBuilderBluePrint.example.bluePrint;

        // Instantiate the first builder
        bluePrint0.instantiate(scope: scope);

        // Instantiating another builder with the same key should throw
        expect(
          () => bluePrint1.instantiate(scope: scope),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains(
                'Another builder with key exampleScBuilder is added.',
              ),
            ),
          ),
        );
      });
    });

    group('special cases', () {
      test('should not multiply apply builders to the same node', () {
        final scope = Scope.example();

        // Create a parent builder
        ScBuilderBluePrint(
          key: 'parent',

          // Create one child builder
          children: ({required hostScope}) {
            return [
              const ScBuilderBluePrint(
                key: 'child',
              ),
            ];
          },
        ).instantiate(scope: scope);

        // Create a scope with one child scope
        final scopeBluePrint = ScopeBluePrint.fromJson({
          'parent': {
            'child': {
              'node': 0,
            },
          },
        });

        // Before fixing the bug, the child builder was applied twice
        scopeBluePrint.instantiate(scope: scope);
      });
    });
  });
}
