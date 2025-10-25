// @license
// Copyright (c) 2025 Dr. Gabriel Gatzsche
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_golden/gg_golden.dart';
import 'package:supply_chain/supply_chain.dart';
import 'package:test/test.dart';

void main() {
  test('Basic Tutorial', () async {
    // ................................
    // Create a supply chain manager
    // Setting isTest to true will apply all changes
    // once flush is called
    final scm = Scm(isTest: true);

    // ................................
    // Create a root scope
    final rootScope = Scope.root(key: 'root', scm: scm);

    // Create a main scope
    const mainScopeBp = ScopeBluePrint(key: 'main');
    final mainScope = mainScopeBp.instantiate(scope: rootScope);

    // ................................
    // Create a suppler node blue print
    const supplierBp = NodeBluePrint<int>(initialProduct: 0, key: 'supplier');

    // Create an instance of the blue print
    final supplier = supplierBp.instantiate(scope: mainScope);

    // Instruct supply chain manager to process the supply chain
    scm.flush();

    // ................................
    // Create a customer node
    final customerBp = NodeBluePrint<int>(
      key: 'customer',
      initialProduct: 1,
      suppliers: ['supplier'],
      produce: (components, previousProduct, node) {
        final supplier = components[0] as int;
        return supplier * 2;
      },
    );

    final customer = customerBp.instantiate(scope: mainScope);

    // Instruct supply chain manager to process the supply chain
    scm.flush();

    // Print the graph
    final graph = rootScope.mermaid();
    await writeGolden(fileName: 'basic_01.mmd', data: graph);

    // Get the customer value
    expect(supplier.product, 0);
    expect(customer.product, 0);

    // Change the supplier value
    supplier.product = 5;

    // Apply the changes
    scm.flush();

    // The customer value is also changed
    expect(supplier.product, 5);
    expect(customer.product, 5 * 2);

    // Search a node
    final foundCustomer0 = rootScope.findNode<int>('customer');
    expect(foundCustomer0, customer);

    final foundCustomer1 = rootScope.findNode<int>('main/customer');
    expect(foundCustomer1, customer);

    final foundCustomer2 = rootScope.findNode<int>('root/main/customer');
    expect(foundCustomer2, customer);

    final foundCustomer3 = rootScope.findNode<int>('xyz');
    expect(foundCustomer3, isNull);

    // Search a scope
    final foundMain = customer.scope.findScope('main');
    expect(foundMain, mainScope);
  });
}
