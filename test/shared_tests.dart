// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';
import 'package:test/test.dart';

// .............................................................................
void placeholderTest() {
  test('should work', () {
    var placeholderValue = 2;
    var replacement0Value = 3;
    var replacement1Value = 4;

    final scope = Scope.example();
    final scm = scope.scm;
    scope.mockContent({
      'a': {
        'b': {
          'c': {
            'height': PlaceholderNodeBluePrint<int>(
              key: 'height',
              initialProduct: placeholderValue,
              realNodePath: 'x.height',
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

    final placeholder = scope.findNode<int>('c.height')!;
    expect(placeholder.bluePrint.isPlaceholder, true);
    final a = scope.findScope('a')!;
    final b = scope.findScope('b')!;
    final customer = scope.findNode<int>('d.customer')!;
    scm.testFlushTasks();

    // ..............................................
    // Use placeholder when no replacement is available

    // Placeholder delivers it's own initial value
    // because no other real height node can be found
    expect(placeholder.product, placeholderValue);

    // The customer uses the place holder
    expect(customer.product, placeholderValue);

    // .........................................
    // Add replacement0 replacing the placeholder

    // Add x.height to the scope a
    a.mockContent({
      'x': {
        'height': replacement0Value,
      },
    });
    final replacement0 = scope.findNode<int>('x.height')!;
    scm.testFlushTasks();

    // Now placeholder should deliver the value of the replacement
    expect(replacement0.product, replacement0Value);
    expect(placeholder.product, replacement0Value);
    expect(customer.product, replacement0Value);

    // Change the replacement
    // Placeholder value should be updated
    replacement0Value *= 10;
    replacement0.product = replacement0Value;
    scm.testFlushTasks();

    expect(replacement0.product, replacement0Value);
    expect(placeholder.product, replacement0Value);
    expect(customer.product, replacement0Value);

    // ..........................................................
    // Insert another replacement1 between placeholder and replacement
    b.mockContent({
      'x': {
        'height': replacement1Value,
      },
    });
    final replacement1 = scope.findNode<int>('b.x.height')!;
    scm.testFlushTasks();

    // Now the placeholder should deliver the value of the new replacement
    expect(replacement0.product, replacement0Value);
    expect(replacement1.product, replacement1Value);
    expect(placeholder.product, replacement1Value);
    expect(customer.product, replacement1Value);

    // .........................................................
    // Remove the replacement1 between  replacement0 and placeholder
    replacement1.dispose();
    scm.testFlushTasks();

    // Now replacement 0 should take over again
    expect(replacement0.product, replacement0Value);
    expect(placeholder.product, replacement0Value);
    expect(customer.product, replacement0Value);

    // .......................
    // Remove the replacement0.
    // Placeholder should take over again
    replacement0.dispose();
    scm.testFlushTasks();

    expect(placeholder.suppliers, isEmpty);
    placeholder.product = placeholderValue;
    expect(placeholder.product, placeholderValue);
    expect(customer.product, placeholderValue);
  });
}
