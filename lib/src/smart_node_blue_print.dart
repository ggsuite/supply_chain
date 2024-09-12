// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';

/// A smartNode node that delivers a smartNode value until
/// a real node is provided
class SmartNodeBluePrint<T> extends NodeBluePrint<T> {
  /// Constructor of the node
  const SmartNodeBluePrint({
    required super.key,
    required super.initialProduct,
    required this.realNodePath,
  });

  /// The path of the real node that will be used
  /// when the real node is found
  final String realNodePath;
}
