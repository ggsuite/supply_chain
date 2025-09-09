// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';
import 'package:test/test.dart';

void main() {
  group('ScBuilderInserts', () {
    group('should recursively iterate all nodes of the host scope', () {
      test('and add the inserts as defined in the builder', () {
        // Look into [ExampleScBuilderBluePrint] to see the node hierarchy
        // used for this example
        final inserts = ScBuilderInserts.example();
        final builder = inserts.builder;
        final scope = builder.scope;

        // Get the nodes out of the example hierarchy
        final hostA = scope.findNode<num>('hostA')!;
        final hostB = scope.findNode<num>('hostB')!;
        final hostC = scope.findNode<num>('hostC')!;
        final other = scope.findNode<num>('other')!;

        // All nodes having a key starting with "host" should have two inserts
        // added by ExampleScBuilderBluePrint
        expect(hostA.inserts, hasLength(2));
        expect(hostA.inserts.elementAt(0).key, 'p0Add111'); // Parent
        expect(hostA.inserts.elementAt(1).key, 'p1MultiplyByTen'); // Parent

        // ScopeB should have 1 additional insert,
        expect(hostB.inserts, hasLength(2 + 1));

        // Root builders a added first, followed by child builders
        expect(hostB.inserts.elementAt(0).key, 'p0Add111'); // Parent
        expect(hostB.inserts.elementAt(1).key, 'p1MultiplyByTen');
        expect(hostB.inserts.elementAt(2).key, 'c0MultiplyByTwo'); // Child

        expect(hostC.inserts, hasLength(2 + 1));

        // Nodes not starting with 'host' should not have inserts
        expect(other.inserts, hasLength(0));

        // The values should be calculated correctly
        final initialA = hostA.bluePrint.initialProduct;
        final productA = hostA.product;
        expect(productA, (initialA + 111) * 10);

        final initialB = hostB.bluePrint.initialProduct;
        final productB = hostB.product;
        expect(productB, (initialB + 111) * 10 * 2);

        final initialC = hostC.bluePrint.initialProduct;
        final productC = hostC.product;
        expect(productC, (initialC + 111) * 10 * 2);

        // Add another node to the scope
        final hostD = const NodeBluePrint<num>(
          key: 'hostD',
          initialProduct: 0,
        ).instantiate(scope: scope);
        expect(hostD.inserts, isNotEmpty);

        // Finally let's dispose the builder
        builder.dispose();
        builder.scope.scm.testFlushTasks();

        // Now the inserts should be removed from all nodes
        expect(hostA.inserts, hasLength(0));
        expect(hostB.inserts, hasLength(0));
        expect(hostC.inserts, hasLength(0));

        // And the nodes should deliver their normal products
        expect(hostA.product, initialA);
        expect(hostB.product, initialB);
        expect(hostC.product, initialC);
      });
    });
  });
}
