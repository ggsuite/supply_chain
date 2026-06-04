// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:async';

import 'package:supply_chain/supply_chain.dart';
import 'package:test/test.dart';

void main() {
  test('Async Tutorial', () async {
    // .............................
    // Create a supply chain manager
    final scm = Scm(isTest: true);
    final rootScope = Scope.root(key: 'root', scm: scm);
    const scopeBp = ScopeBluePrint(key: 'scope');
    final scope = scopeBp.instantiate(scope: rootScope);

    // ..............................
    // Create an asynchronous supplier
    //
    // A produce function may now return a Future. The node stays in production
    // until the future resolves. Customers wait for the result.
    final completer = Completer<int>();

    final supplier = NodeBluePrint<int>(
      key: 'supplier',
      initialProduct: 0,
      // Returning a Future makes this an asynchronous producer.
      produce: (components, previousProduct, node) => completer.future,
    ).instantiate(scope: scope);

    // ......................
    // Create a customer node doubling the supplier's product
    final customer = NodeBluePrint<int>(
      key: 'customer',
      initialProduct: 0,
      suppliers: ['supplier'],
      produce: (components, previousProduct, node) {
        final supplierProduct = components[0] as int;
        return supplierProduct * 2;
      },
    ).instantiate(scope: scope);

    // .................
    // Apply all synchronous changes
    scm.flush();

    // The supplier is still producing - its product and the customer's
    // product keep their initial values.
    expect(supplier.product, 0);
    expect(customer.product, 0);

    // ......................
    // Resolve the asynchronous production
    completer.complete(21);

    // Use settle() instead of flush() to also await in-flight asynchronous
    // productions until the chain is quiescent.
    await scm.settle();

    // The supplier's product is applied and the customer is updated.
    expect(supplier.product, 21);
    expect(customer.product, 42);

    // ............................................
    // Asynchronous productions and the frame budget
    //
    // By default an asynchronous production that exceeds the SCM's frame
    // budget (Scm.timeout, 5ms) is finalized with the previous product so the
    // frame is never blocked. The real result is then applied as a follow-up
    // update once the future resolves.
    //
    // To let a node deliver its result in a single update instead, give it a
    // longer productionTimeout:
    final slowBp = NodeBluePrint<int>(
      key: 'slowSupplier',
      initialProduct: 0,
      productionTimeout: const Duration(seconds: 10),
      produce: (components, previousProduct, node) async => 7,
    );
    final slow = slowBp.instantiate(scope: scope);
    await scm.settle();
    expect(slow.product, 7);
  });
}
