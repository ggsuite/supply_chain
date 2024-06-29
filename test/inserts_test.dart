// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';
import 'package:test/test.dart';

void main() {
  group('Inserts', () {
    group('should recursively iterate all nodes of the host scope', () {
      test('and add the inserts as defined in the plugin', () {
        // Look into [ExamplePluginBluePrint] to see the node hierarchy
        // used for this example
        final inserts = Inserts.example();
        final plugin = inserts.plugin;
        final scope = plugin.scope;

        // Get the nodes out of the example hierarchy
        final hostA = scope.findNode<int>('hostA')!;
        final hostB = scope.findNode<int>('hostB')!;
        final hostC = scope.findNode<int>('hostC')!;
        final other = scope.findNode<int>('other')!;

        // All nodes having a key starting with "host" should have two inserts
        // added by ExamplePluginBluePrint

        // Scope should have 1 additional insert,
        // because
        expect(hostA.inserts, hasLength(2));
        expect(hostB.inserts, hasLength(2 + 1));
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

        // Finally let's dispose the plugin
        plugin.dispose();
        plugin.scope.scm.testFlushTasks();

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
