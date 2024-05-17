// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';
import 'package:test/test.dart';

void main() {
  group('ScopeBluePrint', () {
    group('example', () {
      test('should provide a blue print with to nodes and one dependency', () {
        final scopeBluePrint = ScopeBluePrint.example();
        final [node0 as NodeBluePrint<int>, node1 as NodeBluePrint<int>] =
            scopeBluePrint.nodes;
        final [dependency as NodeBluePrint<int>] =
            scopeBluePrint.fakeDependencies;
        expect(dependency.key, 'Dependency');
        expect(node0.key, 'Node');
        expect(node1.key, 'Customer');
        expect(node0.produce(<dynamic>[5], 0), 6);
        expect(node1.produce(<dynamic>[6], 0), 7);
      });
    });

    group('instantiate(scope)', () {
      group('should instantiate the scope', () {
        group('with fake dependencies', () {
          test('when fakeMissingDependencies == false', () {
            final bluePrint = ScopeBluePrint.example();
            final parentScope = Scope.root(key: 'Root', scm: Scm.example());
            final scope = bluePrint.instantiate(parentScope: parentScope);
            final node = scope.findNode<int>('Dependency');
            expect(node, isNull);
          });
        });

        group('without fake dependencies', () {
          test('when fakeMissingDependencies == true', () {
            final bluePrint = ScopeBluePrint.example();
            final parentScope = Scope.root(key: 'Root', scm: Scm.example());
            final scope = bluePrint.instantiate(
              parentScope: parentScope,
              fakeMissingDependencies: true,
            );
            final node = scope.findNode<int>('Dependency');
            expect(node, isNotNull);
          });
        });
      });
    });

    group('create a graph', () {
      // .......................................................................
      test('should print a simple graph correctly', () async {
        final bluePrint = ScopeBluePrint.example();
        final parentScope = Scope.root(key: 'Outer', scm: Scm.example());
        bluePrint.instantiate(
          parentScope: parentScope,
          fakeMissingDependencies: true,
        );
        parentScope.initSuppliers();

        await parentScope.saveGraphToFile('test/graphs/scope_blue_print.svg');
      });
    });
  });
}
