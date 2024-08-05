// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';
import 'package:test/test.dart';

void main() {
  group('CustomizerNodeReplacer', () {
    group('example', () {
      test('should work', () {
        final customizerNodeReplacer = CustomizerNodeReplacer.example;
        final customizer = customizerNodeReplacer.customizer;
        final scope = customizer.scope;
        scope.scm.testFlushTasks();

        // Get the nodes a,b and d, e out of the hierarchy
        final a = scope.findNode<int>('a')!;
        final b = scope.findNode<int>('b')!;
        final c = scope.findScope('c')!;
        final d = scope.findNode<int>('d')!;
        final e = scope.findNode<int>('e')!;
        final f = scope.findNode<String>('f')!;

        // Because of ExampleCustomizerReplacingIntNodes,
        // the nodes a, b, d, and e should be deliver 42
        expect(a.product, 42);
        expect(b.product, 42);
        expect(d.product, 42);
        expect(e.product, 42);
        expect(f.product, 'f');

        // Customizers should also be applied to nodes and scopes,
        // added after the customizer was instantiated.
        // Lets add another two int nodes to scope  and c:
        // Both nodes should deliver 42 because the customer is applied
        final g = const NodeBluePrint<int>(key: 'g', initialProduct: 7)
            .instantiate(scope: scope);

        final h = const NodeBluePrint<int>(key: 'h', initialProduct: 8)
            .instantiate(scope: c);

        scope.scm.testFlushTasks();
        expect(g.product, 42);
        expect(h.product, 42);

        // Lets dispose the customizer.
        // The nodes a, b, d, and e should be deliver 1, 2, 4, and 5 again
        customizer.dispose();
        scope.scm.testFlushTasks();

        expect(a.product, 1);
        expect(b.product, 2);
        expect(d.product, 4);
        expect(e.product, 5);
        expect(f.product, 'f');

        expect(customizerNodeReplacer, isNotNull);
      });
    });
  });
}
