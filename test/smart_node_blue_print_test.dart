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
    });
  });
}
