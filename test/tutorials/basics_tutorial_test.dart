// @license
// Copyright (c) 2025 Dr. Gabriel Gatzsche
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';
import 'package:test/test.dart';

void main() {
  test('Basic Tutorial', () {
    // ................................
    // Create a supply chain manager
    final scm = Scm();

    // ................................
    // Create a root scope
    final rootScope = Scope.root(key: 'root', scm: scm);

    // Create a main scope
    const mainScopeBp = ScopeBluePrint(key: 'mainScope');
    final mainScope = mainScopeBp.instantiate(scope: rootScope);

    // ................................
    // Create a suppler node blue print
    const supplierBp = NodeBluePrint<int>(
      initialProduct: 0,
      key: 'supplierNode',
    );

    // Create an instance of the blue print
    final supplier = supplierBp.instantiate(scope: mainScope);

    // Instruct supply chain manager to process the supply chain
    scm.testFlushTasks();

    // ................................
    // Create a customer node
    final customerBp = NodeBluePrint<int>(
      key: 'customerNode',
      initialProduct: 1,
      suppliers: ['supplierNodeX'],
      produce: (components, previousProduct) {
        return 2;
      },
    );

    final customer = customerBp.instantiate(scope: mainScope);

    // Instruct supply chain manager to process the supply chain
    scm.testFlushTasks();

    // Print the graph
    final graph = rootScope.mermaid();
    expect(graph, '''''');
  });
}
