// @license
// Copyright (c) 2019 - 2024 ggsuite. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';
import 'package:test/test.dart';

void main() {
  /// A manager creating a row scope for each row
  final ScopeBluePrintFactory factory = ScopeBluePrintFactory.example();

  group('ScopeBluePrintFactory', () {
    group('example', () {
      group('produce()', () {
        test('should turn components into a list of Scopes', () {
          final scope = Scope.example();
          final factoryInstance = factory.instantiate(scope: scope);

          // Test the produce function. It should return a scope blue print
          // for each row height
          final rowHeights = [10, 20, 30];
          final rowScopes = factory.produce([rowHeights], [], factoryInstance);
          expect(rowScopes.length, 3);

          // Each scope should have a "RowHeight" node
          // that produces the row height of the row
          var i = 0;
          for (final rowScope in rowScopes) {
            final rowHeightNode = rowScope.node<int>('rowHeight')!;

            final dummy = Node.example();

            expect(
              rowHeightNode.produce([rowHeights], 0, dummy),
              rowHeights[i],
            );
            i++;
          }
        });
      });
    });
  });
}
