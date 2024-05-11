// @license
// Copyright (c) 2019 - 2023 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';

/// A plant is a producer with an assembly line
class Plant<T> extends Producer<T> {
  /// Constructor
  Plant({
    required super.worker,
  });
}

// #############################################################################
/// Creates an example plant
Plant<int> examplePlant({Node<int>? worker}) =>
    Plant(worker: worker ?? exampleNode());
