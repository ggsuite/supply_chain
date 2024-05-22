// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';
import 'package:test/test.dart';

void main() {
  /// A node delivering a list of row heights
  late final NodeBluePrint<List<int>> rowHeights;

  /// A node delivering one row height for a row
  late final NodeBluePrint<int> rowHeight;

  /// Manages a row
  late final ScopeBluePrint rowScope;

  /// A manager creating a row scope for each row
  late final SubScopeManagerBluePrint rowSubScopeManager;

  setUp(() {
    rowHeights = const NodeBluePrint<List<int>>(
      key: 'RowHeights',
      initialProduct: [],
    );

    rowHeight = const NodeBluePrint<int>(
      key: 'RowHeight',
      initialProduct: 0,
    );

    rowScope = ScopeBluePrint(
      key: 'RowScope',
      nodes: [rowHeight, rowHeights],
      dependencies: [rowHeight],
    );

    rowSubScopeManager = SubScopeManagerBluePrint(
      key: 'RowSubScopeManager',
      suppliers: [rowHeights.key],
      produce: (List<dynamic> components, _) {
        // Take each row height
        // coming from the rowHeights supplier
        // and turn it into a row scope
        final [List<int> rowHeights] = components;
        final rows = <ScopeBluePrint>[];
        int i = 0;
        for (final rowHeightValue in rowHeights) {
          var iCopy = i;

          // Create a node that maps the available row heights
          // to the row height of the current row
          final rowHeightNode = NodeBluePrint<int>(
            key: 'RowHeight',
            initialProduct: rowHeightValue,
            suppliers: ['RowHeights'],

            // Select a row height from row heights
            produce: (components, previousProduct) {
              final [List<int> rowHeights] = components;
              return rowHeights[iCopy];
            },
          );

          // Create a sub scope for a specific row
          final scope = rowScope.copyWith(
            key: 'RowScope$i',
            overrides: [rowHeightNode],
          );
          rows.add(scope);
          i++;
          // Take the rowScope
        }

        return rows;
      },
    );
  });

  group('SubScopeManagerBluePrint', () {
    group('produce()', () {
      test('should turn components into a list of Scopes', () {
        // Test the produce function. It should return a scope blue print
        // for each row height
        final rowHeights = [10, 20, 30];
        final rowScopes = rowSubScopeManager.produce([rowHeights], []);
        expect(rowScopes.length, 3);

        // Each scope should have a "RowHeight" node
        // that produces the row height of the row
        var i = 0;
        for (final rowScope in rowScopes) {
          final rowHeightNode = rowScope.findNode<int>('RowHeight')!;
          expect(rowHeightNode.produce([rowHeights], 0), rowHeights[i]);
          i++;
        }
      });
    });
  });
}
