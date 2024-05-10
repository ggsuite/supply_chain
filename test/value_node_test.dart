// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';
import 'package:test/test.dart';

void main() {
  final valueNode = ValueNode.example;
  final scm = valueNode.scm;

  group('ValueNode', () {
    group('example', () {
      test('should have the right initial values', () {
        expect(valueNode.key, 'ValueNode');
        expect(valueNode.chain.key, 'Example');
        expect(valueNode.product, 5);
        expect(valueNode.isReady, isTrue);
      });

      test('should allow to set values from the outside', () {
        // Set a value
        valueNode.value = 7;
        expect(valueNode.value, 7);

        // A new product should not yet be produced
        expect(valueNode.product, 5);

        // Produce the new product
        scm.tick();
        scm.testFlushTasks();

        // The new value should be the product
        expect(valueNode.product, 7);
      });
    });
  });
}
