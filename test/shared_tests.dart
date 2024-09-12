// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';
import 'package:test/test.dart';

// .............................................................................
void smartNodeTest() {
  test('should work', () {
    var smartNodeValue = 2;
    var smartNode0Value = 3;
    var smartNode1Value = 4;

    final scope = Scope.example();
    final scm = scope.scm;
    scope.mockContent({
      'a': {
        'b': {
          'c': {
            'height': SmartNodeBluePrint<int>(
              key: 'height',
              initialProduct: smartNodeValue,
              master: 'x.height',
            ),
            'd': {
              'customer': NodeBluePrint<int>.map(
                supplier: 'height',
                initialProduct: 0,
                toKey: 'customer',
              ),
            },
          },
        },
      },
    });

    final smartNode = scope.findNode<int>('c.height')!;
    expect(smartNode.bluePrint.isSmartNode, true);
    final a = scope.findScope('a')!;
    final b = scope.findScope('b')!;
    final customer = scope.findNode<int>('d.customer')!;
    scm.testFlushTasks();

    // ..............................................
    // Use smartNode when no smartNode is available

    // SmartNode delivers it's own initial value
    // because no other master height node can be found
    expect(smartNode.product, smartNodeValue);

    // The customer uses the place holder
    expect(customer.product, smartNodeValue);

    // .........................................
    // Add smartNode0 replacing the smartNode

    // Add x.height to the scope a
    a.mockContent({
      'x': {
        'height': smartNode0Value,
      },
    });
    final smartNode0 = scope.findNode<int>('x.height')!;
    scm.testFlushTasks();

    // Now smartNode should deliver the value of the smartNode
    expect(smartNode0.product, smartNode0Value);
    expect(smartNode.product, smartNode0Value);
    expect(customer.product, smartNode0Value);

    // Change the smartNode
    // SmartNode value should be updated
    smartNode0Value *= 10;
    smartNode0.product = smartNode0Value;
    scm.testFlushTasks();

    expect(smartNode0.product, smartNode0Value);
    expect(smartNode.product, smartNode0Value);
    expect(customer.product, smartNode0Value);

    // ..........................................................
    // Insert another smartNode1 between smartNode and smartNode
    b.mockContent({
      'x': {
        'height': smartNode1Value,
      },
    });
    final smartNode1 = scope.findNode<int>('b.x.height')!;
    scm.testFlushTasks();

    // Now the smartNode should deliver the value of the new smartNode
    expect(smartNode0.product, smartNode0Value);
    expect(smartNode1.product, smartNode1Value);
    expect(smartNode.product, smartNode1Value);
    expect(customer.product, smartNode1Value);

    // .........................................................
    // Remove the smartNode1 between  smartNode0 and smartNode
    smartNode1.dispose();
    scm.testFlushTasks();

    // Now smartNode 0 should take over again
    expect(smartNode0.product, smartNode0Value);
    expect(smartNode.product, smartNode0Value);
    expect(customer.product, smartNode0Value);

    // .......................
    // Remove the smartNode0.
    // SmartNode should take over again
    smartNode0.dispose();
    scm.testFlushTasks();

    expect(smartNode.suppliers, isEmpty);
    smartNode.product = smartNodeValue;
    expect(smartNode.product, smartNodeValue);
    expect(customer.product, smartNodeValue);
  });
}
