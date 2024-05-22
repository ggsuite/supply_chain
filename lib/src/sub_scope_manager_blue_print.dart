// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';

/// Adds sub scope to the current scope depending on the products given
/// by suppliers
class SubScopeManagerBluePrint extends NodeBluePrint<List<ScopeBluePrint>> {
  /// Constructor
  const SubScopeManagerBluePrint({
    required super.key,
    required super.suppliers,
    super.initialProduct = const <ScopeBluePrint>[],
    required super.produce,
  });
}
