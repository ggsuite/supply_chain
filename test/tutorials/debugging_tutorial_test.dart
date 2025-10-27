// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';
import 'package:test/test.dart';

void main() {
  test('Debugging Tutorial', () async {
    // Create a supply chain
    final main = Scope.example();
    final scm = main.scm;

    // Create a supplier that delivers an int
    final supplier = const NodeBluePrint(
      key: 'supplier',
      initialProduct: 1,
    ).instantiate(scope: main);

    // Create a producer blue print which doubles the value provided by supplier
    final producer = NodeBluePrint(
      key: 'producer',
      initialProduct: 0,
      suppliers: ['supplier'],
      produce: (components, previousProduct, node) {
        final [int val] = components;
        return val * 2;
      },
    );

    // Create three child scopes within main
    final child0 = const ScopeBluePrint(key: 'child0').instantiate(scope: main);
    final child1 = const ScopeBluePrint(key: 'child1').instantiate(scope: main);
    final child2 = const ScopeBluePrint(key: 'child2').instantiate(scope: main);

    // Within each of the child scope, instantiate a producer
    final producer0 = producer.instantiate(scope: child0);
    final producer1 = producer.instantiate(scope: child1);
    final producer2 = producer.instantiate(scope: child2);

    // Apply all changes
    scm.flush();

    // Now all producers will have the supplier doubled value
    expect(supplier.product, 1);
    expect(producer0.product, 2);
    expect(producer1.product, 2);
    expect(producer2.product, 2);

    // Place a breakpoint in the produce function at the line "return val * 2;"
    // Run this test in debugging mode.
    // The breakpoint will stop three times, for producer0, 1 and 2.

    // How can you make sure, that the breakpoint only stops for producer1?

    // 1. List all node paths of the supply chain.
    final paths = main.ls();
    expect(paths, [
      'child0',
      'child0/producer',
      'child1',
      'child1/producer',
      'child2',
      'child2/producer',
      'supplier',
    ]);

    // 2. Identify the path of producer1, i.e. "child1/producer"

    // 3. Edit the breakpoint created before and add the following condition:
    // node.path.contains('child1/producer')

    // 4. Re-run the tests in debugging node. The debugger now will stop only
    // on producer1. Print "node.path" to see if this is true.
  });
}
