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
    var master0Value = 3;
    var master1Value = 4;

    final scope = Scope.example();
    final scm = scope.scm;
    scope.mockContent({
      'a': {
        'b': {
          'c': {
            'height': SmartNodeBluePrint<int>(
              key: 'height',
              initialProduct: smartNodeValue,
              master: ['x', 'height'],
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
    // Use smartNode itself when no smartNode is available

    // SmartNode delivers it's own initial value
    // because no other master height node can be found
    expect(smartNode.product, smartNodeValue);

    // The customer uses the place holder
    expect(customer.product, smartNodeValue);

    // .........................................
    // Add master0 replacing the smartNode

    // Add x.height to the scope a
    a.mockContent({
      'x': {
        'height': master0Value,
      },
    });
    final master0 = scope.findNode<int>('x.height')!;
    scm.testFlushTasks();

    // Now master0 should deliver the value of the smartNode
    expect(master0.product, master0Value);
    expect(smartNode.product, master0Value);
    expect(customer.product, master0Value);

    // Change the master0
    // SmartNode value should be updated
    master0Value *= 10;
    master0.product = master0Value;
    scm.testFlushTasks();

    expect(master0.product, master0Value);
    expect(smartNode.product, master0Value);
    expect(customer.product, master0Value);

    // ..........................................................
    // Insert another master1 between smartNode and master0
    b.mockContent({
      'x': {
        'height': master1Value,
      },
    });
    final master1 = scope.findNode<int>('b.x.height')!;
    scm.testFlushTasks();

    // Now the smartNode should deliver the value of the new smartNode
    expect(master0.product, master0Value);
    expect(master1.product, master1Value);
    expect(smartNode.product, master1Value);
    expect(customer.product, master1Value);

    // .........................................................
    // Remove the master1 between  smartNode and master0
    master1.dispose();
    scm.testFlushTasks();

    // Now master0 should take over again
    expect(master0.product, master0Value);
    expect(smartNode.product, master0Value);
    expect(customer.product, master0Value);

    // .......................
    // Remove the master0.
    // SmartNode should take over again
    master0.dispose();
    scm.testFlushTasks();

    expect(smartNode.suppliers, isEmpty);
    smartNode.product = smartNodeValue;
    expect(smartNode.product, smartNodeValue);
    expect(customer.product, smartNodeValue);
  });

  test('should be able to connect to a master in own scope', () {
    final scope = Scope.example();
    final scm = scope.scm;
    scope.mockContent({
      'a': 5,
      'b': const SmartNodeBluePrint(key: 'b', initialProduct: 1, master: ['a']),
    });
    scm.testFlushTasks();
    expect(scope.findNode<int>('b')!.product, 5);
  });

  test('should remove suppliers from disposed smart nodes', () {
    final scope = Scope.example();
    final scm = scope.scm;

    // Create two sibling nodes that might reference each other.
    scope.mockContent(
      {
        'scope0': {
          'master': 0,
          'a': {
            'smartNode': const SmartNodeBluePrint(
              key: 'smartNode',
              master: ['master'],
              initialProduct: 1,
            ),
          },
        },
      },
    );

    scm.testFlushTasks();

    final master = scope.findNode<int>('master')!;
    final smartNode = scope.findNode<int>('smartNode')!;
    expect(smartNode.suppliers, [master]);

    // Dispose smart node
    smartNode.dispose();

    // The smart node should not have any suppliers anymore.
    expect(smartNode.suppliers, isEmpty);
  });
}
