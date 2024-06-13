// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:collection/collection.dart';
import 'package:supply_chain/supply_chain.dart';

/// Produce delegate that does nothing
T doNothing<T>(List<dynamic> components, T previousProduct) => previousProduct;

/// The configuration of a node
class NodeBluePrint<T> {
  /// Constructor of the node
  const NodeBluePrint({
    required this.key,
    required this.initialProduct,
    this.documentation = '',
    this.suppliers = const <String>[],
    Produce<T>? produce,
  }) : produce = produce ?? doNothing<T>;

  /// Maps a supplier to a different key
  factory NodeBluePrint.map({
    required String supplier,
    required String toKey,
    required T initialProduct,
  }) {
    return NodeBluePrint(
      key: toKey,
      initialProduct: initialProduct,
      suppliers: [supplier],
      produce: (components, previous) => components.first as T,
    );
  }

  /// Checks if the configuration is valid
  void check() {
    assert(key.isNotEmpty, 'The key must not be empty');
    assert(key.isCamelCase, 'The key must be in CamelCase');
    produce([], initialProduct);
    assert(
      !(suppliers.isNotEmpty && produce == doNothing<T>),
      'If suppliers are not empty, a produce function must be provided',
    );
  }

  /// The initial product of the node
  final T initialProduct;

  /// The key of this node
  final String key;

  /// The documentation of the node
  final String documentation;

  /// A list of supplier keys
  final Iterable<String> suppliers;

  /// The produce function
  final Produce<T> produce;

  /// An example instance for test purposes
  static NodeBluePrint<int> example({
    String? key,
    Produce<int>? produce,
  }) =>
      NodeBluePrint<int>(
        key: key ?? nextKey,
        initialProduct: 0,
        suppliers: [],
        produce:
            produce ?? (components, previousProduct) => previousProduct + 1,
      );

  /// Instantiates the blue print in the given scope
  Node<T> instantiate({
    required Scope scope,
  }) {
    final node = scope.nodes.firstWhereOrNull((n) => n.key == key);

    if (node != null) {
      assert(node is Node<T>, 'The node must be of type Node<T>');
      return node as Node<T>;
    }

    return Node<T>(
      bluePrint: this,
      scope: scope,
    );
  }

  /// Instantiates the blue print as plugin in the given scope
  PluginNode<T> instantiateAsPlugin({
    required Node<T> host,
    int? index,
  }) {
    return PluginNode<T>(
      bluePrint: this,
      host: host,
      index: index,
    );
  }

  /// Create a modified copy of the blue print
  NodeBluePrint<T> copyWith({
    T? initialProduct,
    String? key,
    Iterable<String>? suppliers,
    Produce<T>? produce,
  }) {
    return NodeBluePrint<T>(
      initialProduct: initialProduct ?? this.initialProduct,
      key: key ?? this.key,
      suppliers: suppliers ?? this.suppliers,
      produce: produce ?? this.produce,
    );
  }

  /// Maps the key of the blue print to another key
  NodeBluePrint<T> forwardTo(String toKey) => NodeBluePrint.map(
        supplier: key,
        toKey: toKey,
        initialProduct: initialProduct,
      );

  /// Maps the key of the blue print to another key
  NodeBluePrint<T> forwardFrom(String supplier) => NodeBluePrint.map(
        supplier: supplier,
        toKey: key,
        initialProduct: initialProduct,
      );

  /// Provites an operator =
  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }

    if (other is NodeBluePrint<T>) {
      if (suppliers.length != other.suppliers.length) {
        return false;
      }

      for (int i = 0; i < suppliers.length; i++) {
        if (suppliers.elementAt(i) != other.suppliers.elementAt(i)) {
          return false;
        }
      }

      return key == other.key &&
          initialProduct == other.initialProduct &&
          other.produce == produce;
    }
    return false;
  }

  @override
  int get hashCode {
    final suppliersHash = suppliers.fold<int>(
      0,
      (previousValue, element) => previousValue ^ element.hashCode,
    );

    return key.hashCode ^
        initialProduct.hashCode ^
        produce.hashCode ^
        suppliersHash;
  }

  @override
  String toString() => key;
}
