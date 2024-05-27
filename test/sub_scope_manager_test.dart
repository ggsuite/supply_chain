// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:mocktail/mocktail.dart';
import 'package:supply_chain/supply_chain.dart';
import 'package:test/test.dart';

void main() {
  group('SubScopeManager', () {
    group('example', () {
      test('should work', () {
        // Get some variables
        final subScopeManager = SubScopeManager.example();
        final scope = subScopeManager.scope;
        final scm = scope.scm;
        final rowHeightsNode = scope.findNode<List<int>>('RowHeights')!;
        expect(rowHeightsNode, isNotNull);

        // Init suppliers
        scope.initSuppliers();

        // Let the SCM produce
        scm.tick();
        scm.testFlushTasks();

        // Initially no row scopes should be created
        expect(scope.children, isEmpty);

        // Assume some row heights are coming in
        rowHeightsNode.product = [10, 20, 30];
        scm.tick();
        scm.testFlushTasks();
        expect(scm.nodes, hasLength(5));

        // Now we should have 3 row scopes
        expect(scope.children.length, 3);
        final row0 = scope.child('Row0')!;
        final row1 = scope.child('Row1')!;
        final row2 = scope.child('Row2')!;

        // Each row scope should have the right height
        expect(row0.node<int>(key: 'RowHeight')?.product, 10);
        expect(row1.node<int>(key: 'RowHeight')?.product, 20);
        expect(row2.node<int>(key: 'RowHeight')?.product, 30);

        // Update the row heights
        rowHeightsNode.product = [40, 50, 60, 70];

        scm.tick();
        scm.testFlushTasks(); // Note: One flush should be enough. Check this.
        scm.tick();
        scm.testFlushTasks();
        expect(scm.nodes, hasLength(6));

        // The row scopes should have the new heights
        final row3 = scope.child('Row3')!;
        expect(row0.node<int>(key: 'RowHeight')?.product, 40);
        expect(row1.node<int>(key: 'RowHeight')?.product, 50);
        expect(row2.node<int>(key: 'RowHeight')?.product, 60);
        expect(row3.node<int>(key: 'RowHeight')?.product, 70);

        // Remove row heights
        rowHeightsNode.product = [10];
        scm.tick();
        scm.testFlushTasks(); // Note: One flush should be enough. Check this.
        expect(scm.nodes, hasLength(3));
        expect(scope.children.length, 1);
        expect(row0.node<int>(key: 'RowHeight')?.product, 10);
      });
    });

    test('should handle added and removed nodes correctly', () {
      // Instantiate a new sub scope manager
      // and hand over a MockSubScopeManagerBluePrint.
      final bluePrint = MockSubScopeManagerBluePrint();
      var producedScopeBluePrints = <ScopeBluePrint>[];

      when(() => bluePrint.initialProduct).thenReturn([]);
      when(() => bluePrint.key).thenReturn('SubScopeManager');
      when(() => bluePrint.suppliers).thenReturn(['RowHeights']);
      when(() => bluePrint.produce).thenReturn(
        (List<dynamic> components, List<ScopeBluePrint> previous) =>
            producedScopeBluePrints,
      );

      final scope = Scope.example();
      final scm = scope.scm;

      final subScopeManager = SubScopeManager(
        bluePrint: bluePrint,
        scope: scope,
      );

      // Call the produce method and make the blue print behaving in a way
      // adding and removing nodes is tested.
      subScopeManager.produce(announce: false);
      expect(scm.nodes, hasLength(1));

      // Assume that the produce method adds a child scope
      producedScopeBluePrints = [
        ScopeBluePrint(
          key: 'Row0',
          nodes: [
            NodeBluePrint<int>(
              key: 'RowHeight',
              initialProduct: 10,
              suppliers: [],
              produce: (components, previousProduct) => 10,
            ),
          ],
          dependencies: [],
        ),
      ];

      subScopeManager.produce(announce: false);
      expect(scm.nodes, hasLength(2));

      // Change the produced scope. It should add one additional node.
      producedScopeBluePrints = [
        ScopeBluePrint(
          key: 'Row0',
          nodes: [
            NodeBluePrint<int>(
              key: 'RowHeight',
              initialProduct: 10,
              suppliers: [],
              produce: (components, previousProduct) => 10,
            ),
            NodeBluePrint<int>(
              key: 'RowHeight2',
              initialProduct: 20,
              suppliers: [],
              produce: (components, previousProduct) => 20,
            ),
          ],
          dependencies: [],
        ),
      ];

      subScopeManager.produce(announce: false);
      expect(scm.nodes, hasLength(3));

      // Change the produced scope. It should remove the last node.
      producedScopeBluePrints = [
        ScopeBluePrint(
          key: 'Row0',
          nodes: [
            NodeBluePrint<int>(
              key: 'RowHeight',
              initialProduct: 10,
              suppliers: [],
              produce: (components, previousProduct) => 10,
            ),
          ],
          dependencies: [],
        ),
      ];
      subScopeManager.produce(announce: false);
      expect(scm.nodes, hasLength(2));
    });
  });
}
