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
                master: 'hello',
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
              master: 'a',
              initialProduct: 0,
            ),
          },
          'scope1': {
            'a': const SmartNodeBluePrint(
              key: 'a',
              master: 'a',
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
              master: 'slot.height',
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
    });
  });
}
