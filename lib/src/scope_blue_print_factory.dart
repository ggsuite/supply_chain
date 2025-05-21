// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';

/// A node producing scope blue prints depending on components
///  provided by suppliers
class ScopeBluePrintFactory extends NodeBluePrint<List<ScopeBluePrint>> {
  /// Constructor
  const ScopeBluePrintFactory({
    required super.key,
    required super.suppliers,
    super.initialProduct = const <ScopeBluePrint>[],
    required super.produce,
  });

  // ...........................................................................
  /// Example instance for test purposes:
  /// A ScopeBluePrintFactory that turns to a list of row heights
  /// into a list of scopes for each row.
  factory ScopeBluePrintFactory.example() {
    final rowScopeBluePrintFactory = ScopeBluePrintFactory(
      key: 'scopeFactory',
      suppliers: ['rowHeights'],
      produce: (List<dynamic> components, _) {
        // Get the rowHeights from the suppliers
        final [List<int> rowHeights] = components;

        // Initialize the result array containing the scopes for each row
        final resultScopes = <ScopeBluePrint>[];

        // Iterate all row heights received from the supplier
        int i = 0;
        for (final rowHeight in rowHeights) {
          var iCopy = i;

          // Create a node produce the row height for the specific row.
          final rowHeightNode = NodeBluePrint<int>(
            key: 'rowHeight',
            initialProduct: rowHeight,
            suppliers: ['rowHeights'],
            produce: (components, previousProduct) {
              final [List<int> rowHeights] = components;
              return rowHeights[iCopy];
            },
          );

          // Create the scope for the row
          final scope = ScopeBluePrint(
            key: 'row$iCopy',
            nodes: [rowHeightNode],
          );

          // Add the row scope to the result
          resultScopes.add(scope);
          i++;
        }

        // Return the result scope
        return resultScopes;
      },
    );

    return rowScopeBluePrintFactory;
  }
}
