// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';

/// Sub-chain manager setups sub chains
/// depending on the components delivered by suppliers
class SubChainManagerBluePrint extends NodeBluePrint<List<ScopeBluePrint>> {
  /// Constructor of the sub-chain manager
  const SubChainManagerBluePrint({
    required super.key,
    required super.suppliers,
    required super.produce,
    super.initialProduct = const [],
  });

  /// An example instance for test purposes
  static const example = SubChainManagerBluePrint(
    key: 'SubChainManager',
    suppliers: [],
    produce: doNothing,
  );
}
