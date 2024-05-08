// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import '../supply_chain.dart';

/// A node that just produces a value that can be set from the outside.
class ValueNode<T> extends Node<T> {
  /// Constructor
  ValueNode({
    required super.initialProduct,
    required super.scope,
    required super.key,
  })  : _value = initialProduct,
        super(produce: (c, p) => initialProduct);

  /// The value of the node
  T get value => _value;

  /// Sets the value of the node
  set value(T value) {
    _value = value;
    scm.nominate(this);
  }

  /// Produces the value set before
  @override
  void produce() {
    if (_value != product) {
      product = _value;
      scm.hasNewProduct(this);
    }
  }

  /// Example instance for test purposes
  static ValueNode<int> get example => ValueNode<int>(
        initialProduct: 5,
        scope: Scope.example(),
        key: 'ValueNode',
      );

  /// The value of the node
  T _value;
}
