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

      test('should apply builders to scopes created by builders', () {
        // Create a first builder marking all panel nodes
        final panelMarker = ScBuilderBluePrint(
          key: 'panelMarker',
          addNodes: ({required hostScope}) {
            if (hostScope.key == 'panel') {
              return [
                const NodeBluePrint<int>(key: 'mark', initialProduct: 0),
              ];
            }
            return null;
          },
        );

        // Create a scond builder that creates panel nodes
        final panelCreator = ScBuilderBluePrint(
          key: 'panelCreator',
          addScopes: ({required hostScope}) {
            if (hostScope.key == 'container') {
              return [
                const ScopeBluePrint(key: 'panel'),
              ];
            }

            return [];
          },
        );

        // Create a scope
        final scope = Scope.example();

        // Apply panelMarker to the scope
        panelMarker.instantiate(scope: scope);
        scope.scm.testFlushTasks();

        // Add a panel to the scope
        ScopeBluePrint.fromJson({
          'panel': {
            'height': 100,
          },
        }).instantiate(scope: scope);

        scope.scm.testFlushTasks();

        // The panelMarker should have marked the panel node
        final panel = scope.findScope('panel')!;
        expect(panel.node<int>('mark'), isNotNull);

        // Now add a container scope
        const ScopeBluePrint(key: 'container').instantiate(scope: scope);

        // Instantiate the panelCreateor which adds a panel to the container
        panelCreator.instantiate(scope: scope);
        scope.scm.testFlushTasks();

        // A panel should be added to the container
        final container = scope.findScope('container')!;
        expect(container.child('panel'), isNotNull);

        // The marker builder should have recognized the new panel
        // and have marked it
        final addedPanel = container.findScope('panel')!;
        expect(addedPanel.node<int>('mark'), isNotNull);
      });
    });
  });
}
