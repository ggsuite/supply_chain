// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';

/// A blue print for an insert node
class InsertBluePrint<T> extends NodeBluePrint<T> {
  /// Constructor of the insert node
  const InsertBluePrint({
    required super.key,
    required super.initialProduct,
    super.documentation,
    super.suppliers,
    super.allowedProducts,
    super.produce,
  });

  /// Returns true if node is an insert
  @override
  bool get isInsert => true;

  /// Creates an example insert node blue print
  static InsertBluePrint<int> example({
    String? key,
    Produce<int>? produce,
  }) =>
      InsertBluePrint<int>(
        key: key ?? 'insert',
        initialProduct: 0,
        produce:
            produce ?? (components, previousProduct) => (previousProduct + 1),
      );

  /// Instantiates the blue print as insert in the given scope
  Insert<T> instantiateAsInsert({
    required Node<T> host,
    Scope? scope,
    int? index,
  }) {
    return Insert<T>(
      bluePrint: this,
      host: host,
      index: index,
      scope: scope,
    );
  }
}
