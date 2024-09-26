// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';
import 'package:test/test.dart';

import 'shared_tests.dart';

void main() {
  group('SmartNodeBluePrint', () {
    group('shared tests', () {
      smartNodeTest();
    });

    group('special cases', () {
      test(
        'should find a master node that has the smart node\'s key as path',
        () {
          final scope = Scope.example();
          final scm = scope.scm;
          const masterInitialProduct = 1;
          scope.mockContent({
            // Define an outer node hello
            'hello': masterInitialProduct,
            'inner': {
              // Define an inner smart node hello
              // connecting to the outer node.
              'hello': const SmartNodeBluePrint(
                initialProduct: 123,
                key: 'hello',
                master: ['hello'],
              ),
            },
          });
          scm.testFlushTasks();
          final smartValue = scope.findNode<int>('inner.hello')!;
          final masterValue = scope.findNode<int>('hello')!;

          // The smart node should have the same product as the master node.
          expect(smartValue.product, masterInitialProduct);
          expect(smartValue.product, masterValue.product);
        },
      );

      test('should not select master nodes that define a circular dependency',
          () {
        final scope = Scope.example();
        final scm = scope.scm;

        // Create two sibling nodes that might reference each other.
        scope.mockContent({
          'scope0': {
            'a': const SmartNodeBluePrint(
              key: 'a',
              master: ['a'],
              initialProduct: 0,
            ),
          },
          'scope1': {
            'a': const SmartNodeBluePrint(
              key: 'a',
              master: ['a'],
              initialProduct: 0,
            ),
          },
        });

        scm.testFlushTasks();
      });

      test('should not autoconnect to own node when matching', () {
        final scope = Scope.example();
        final scm = scope.scm;

        // Create a slot blue print where slot.height is a smart node
        // inheriting from parent slot.height.
        final slot = ScopeBluePrint.fromJson({
          'slot': {
            'height': const SmartNodeBluePrint(
              key: 'height',
              master: ['slot', 'height'],
              initialProduct: 0,
            ),
          },
        });

        // Instantiate a first outer slot
        final outerSlot = slot.instantiate(scope: scope);

        // Instantiate a second inner slot
        final innerSlot = slot.instantiate(scope: outerSlot);
        scm.testFlushTasks();

        // The inner slot should take over the value from the outer slot
        final outerHeight = outerSlot.findNode<int>('slot.height')!;
        final innerHeight = innerSlot.findNode<int>('slot.height')!;

        expect(outerHeight, isNot(innerHeight));
        outerHeight.product = 25;
        scm.testFlushTasks();
        expect(innerHeight.product, 25);
      });

      test('should handle structure changes during production', () {
        final scope = Scope.example();
        final scm = scope.scm;

        // Create a slot hierarchy where every slot provides a height
        scope.mockContent({
          'height': 100,
          'slot': {
            'height': const SmartNodeBluePrint<int>(
              key: 'height',
              master: ['height'],
              initialProduct: 0,
            ),
          },
          'corpus': {
            'slot': {
              'height': const SmartNodeBluePrint<int>(
                key: 'height',
                master: ['slot', 'height'],
                initialProduct: 0,
              ),
            },
            'panels': {
              'slot': {
                'height': const SmartNodeBluePrint<int>(
                  key: 'height',
                  master: ['slot', 'height'],
                  initialProduct: 0,
                ),
              },
              'back': {
                'slot': {
                  'height': const SmartNodeBluePrint<int>(
                    key: 'height',
                    master: ['slot', 'height'],
                    initialProduct: 0,
                  ),
                },
              },
            },
          },
        });
        scm.testFlushTasks();

        // Create a builder adding more smart nodes while production
        final builder = ScBuilderBluePrint(
          key: 'interiorBuilder',

          shouldStopProcessingAfter: (scope) => scope.key == 'corpus',

          // Prive a container count node
          addNodes: ({required hostScope}) {
            if (hostScope.key == 'corpus') {
              return [
                const NodeBluePrint<int>(
                  key: 'containerCount',
                  initialProduct: 1,
                ),
              ];
            }
            return null;
          },

          // Build a container when container count changes
          needsUpdateSuppliers: ['containerCount'],
          needsUpdate: ({required components, required hostScope}) {
            final corpus = hostScope.child('corpus')!;
            final interior = corpus.findOrCreateChild('interior');

            final count = components.first as int;
            for (int i = 0; i < count; i++) {
              final existing = interior.child('container$i');
              existing?.dispose();

              ScopeBluePrint(
                key: 'container$i',
                children: [
                  ScopeBluePrint.fromJson({
                    'slot': {
                      'height': const SmartNodeBluePrint<int>(
                        key: 'height',
                        master: ['slot', 'height'],
                        initialProduct: 0,
                      ),
                    },
                  }),
                  ScopeBluePrint.fromJson({
                    'panel': {
                      'height': const SmartNodeBluePrint<int>(
                        key: 'height',
                        master: ['panels', 'slot', 'height'],
                        initialProduct: 0,
                      ),
                    },
                  }),
                ],
              ).instantiate(scope: interior);
            }
          },
        );

        builder.instantiate(scope: scope);
        scm.testFlushTasks();

        // Initially we 0 containers
        final height = scope.findNode<int>('root.example.height')!;
        expect(height.path, 'root.example.height');
        final corpusHeight = scope.findNode<int>('corpus.slot.height')!;
        final panelsHeight = scope.findNode<int>('corpus.panels.slot.height')!;
        final backHeight =
            scope.findNode<int>('corpus.panels.back.slot.height')!;

        Node<int> container0Height() =>
            scope.findNode<int>('interior.container0.slot.height')!;

        Node<int> panel0Height() =>
            scope.findNode<int>('interior.container0.panel.height')!;

        // Increase the number of containers
        final count = scope.findNode<int>('corpus.containerCount')!;
        count.product = 2;
        scm.testFlushTasks();

        final container1Height =
            scope.findNode<int>('interior.container1.slot.height')!;

        Node<int> panel1Height() =>
            scope.findNode<int>('interior.container1.panel.height')!;

        // height should be forwarded to the connected smart nodes
        height.product = 200;
        scm.testFlushTasks();
        expect(corpusHeight.product, 200);
        expect(panelsHeight.product, 200);
        expect(backHeight.product, 200);
        expect(container0Height().product, 200);
        expect(panel0Height().product, 200);
        expect(container1Height.product, 200);
        expect(panel1Height().product, 200);
      });
    });
  });
}
