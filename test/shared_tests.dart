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
    var replacement0Value = 3;
    var replacement1Value = 4;

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
    expect(smartNode.bluePrint.isPlaceholder, true);
    final a = scope.findScope('a')!;
    final b = scope.findScope('b')!;
    final customer = scope.findNode<int>('d.customer')!;
    scm.testFlushTasks();

    // ..............................................
    // Use smartNode when no replacement is available

    // Placeholder delivers it's own initial value
    // because no other master height node can be found
    expect(smartNode.product, smartNodeValue);

    // The customer uses the place holder
    expect(customer.product, smartNodeValue);

    // .........................................
    // Add replacement0 replacing the smartNode

    // Add x.height to the scope a
    a.mockContent({
      'x': {
        'height': replacement0Value,
      },
    });
    final replacement0 = scope.findNode<int>('x.height')!;
    scm.testFlushTasks();

    // Now smartNode should deliver the value of the replacement
    expect(replacement0.product, replacement0Value);
    expect(smartNode.product, replacement0Value);
    expect(customer.product, replacement0Value);

    // Change the replacement
    // Placeholder value should be updated
    replacement0Value *= 10;
    replacement0.product = replacement0Value;
    scm.testFlushTasks();

    expect(replacement0.product, replacement0Value);
    expect(smartNode.product, replacement0Value);
    expect(customer.product, replacement0Value);

    // ..........................................................
    // Insert another replacement1 between smartNode and replacement
    b.mockContent({
      'x': {
        'height': replacement1Value,
      },
    });
    final replacement1 = scope.findNode<int>('b.x.height')!;
    scm.testFlushTasks();

    // Now the smartNode should deliver the value of the new replacement
    expect(replacement0.product, replacement0Value);
    expect(replacement1.product, replacement1Value);
    expect(smartNode.product, replacement1Value);
    expect(customer.product, replacement1Value);

    // .........................................................
    // Remove the replacement1 between  replacement0 and smartNode
    replacement1.dispose();
    scm.testFlushTasks();

    // Now replacement 0 should take over again
    expect(replacement0.product, replacement0Value);
    expect(smartNode.product, replacement0Value);
    expect(customer.product, replacement0Value);

    // .......................
    // Remove the replacement0.
    // Placeholder should take over again
    replacement0.dispose();
    scm.testFlushTasks();

    expect(smartNode.suppliers, isEmpty);
    smartNode.product = smartNodeValue;
    expect(smartNode.product, smartNodeValue);
    expect(customer.product, smartNodeValue);
  });
}
