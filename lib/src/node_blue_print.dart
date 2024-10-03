// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:collection/collection.dart';
import 'package:supply_chain/supply_chain.dart';

/// Produce delegate that does nothing
T doNothing<T>(List<dynamic> components, T previousProduct) => previousProduct;

// .............................................................................
/// Forwards the node from
NodeBluePrint<T> nbp<T>({
  required List<String> from,
  required String to,
  required T init,
  Produce<T>? produce,
}) =>
    NodeBluePrint(
      key: to,
      initialProduct: init,
      suppliers: from,
      produce: produce ?? doNothing,
    );

// .............................................................................
/// The blue print of a node
///
/// - [key] The key of the node
/// - [initialProduct] The initial product of the node
/// - [documentation] The documentation of the node
/// - [suppliers] A list of supplier pathes
/// - [allowedProducts] A list of allowed products
/// - [produce] The produce function
/// - [smartMaster] The smart master of this node
class NodeBluePrint<T> {
  /// Constructor of the node
  const NodeBluePrint({
    required this.key,
    required this.initialProduct,
    this.documentation = '',
    this.suppliers = const <String>[],
    this.allowedProducts = const [],
    Produce<T>? produce,
    this.smartMaster = const [],
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

  // ...........................................................................
  /// Checks if the configuration is valid
  void check() {
    assert(key.isNotEmpty, 'The key must not be empty');
    assert(key.isCamelCase, 'The key must be in CamelCase');

    if (suppliers.toSet().toList().length != suppliers.length) {
      throw ArgumentError('The suppliers must be unique.');
    }
  }

  /// The initial product of the node
  final T initialProduct;

  /// The key of this node
  final String key;

  /// The documentation of the node
  final String documentation;

  /// A list of supplier keys
  final Iterable<String> suppliers;

  /// A list of allowed values
  final List<T> allowedProducts;

  /// The produce function
  final Produce<T> produce;

  // ...........................................................................
  /// Returns true if this node is a smart node, i.e. it has a smartMaster
  bool get isSmartNode => smartMaster.isNotEmpty;

  /// If set this node will automatically connect to the smartMaster and
  /// take over it's values once it is available.
  final List<String> smartMaster;

  // ...........................................................................
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

  // ...........................................................................
  /// Instantiates the blue print in the given scope
  Node<T> instantiate({
    required Scope scope,
    bool applyScBuilders = true,
    Owner<Node<dynamic>>? owner,
  }) {
    check();
    final node = scope.nodes.firstWhereOrNull((n) => n.key == key);

    if (node != null && !node.isDisposed) {
      assert(node is Node<T>, 'The node must be of type Node<T>');
      return node as Node<T>;
    }

    final result = Node<T>(
      bluePrint: this,
      scope: scope,
      owner: owner,
    );

    if (applyScBuilders) {
      _applyScBuilders(result);
    }

    return result;
  }

  // ...........................................................................
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

  // ...........................................................................
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

  /// Makes the node forwarding the value of the supplier
  NodeBluePrint<T> connectSupplier(String supplier) => NodeBluePrint.map(
        supplier: supplier,
        toKey: key,
        initialProduct: initialProduct,
      );

  /// Provites an operator =
  bool equals(Object other) {
    if (other is NodeBluePrint<T>) {
      if (key != other.key) {
        return false;
      }

      if (initialProduct != other.initialProduct) {
        return false;
      }

      if (suppliers.length != other.suppliers.length) {
        return false;
      }

      if (!identical(produce, other.produce)) {
        return false;
      }

      for (int i = 0; i < suppliers.length; i++) {
        if (suppliers.elementAt(i) != other.suppliers.elementAt(i)) {
          return false;
        }
      }

      return true;
    } else {
      return false;
    }
  }

  @override
  // ignore: hash_and_equals
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

  // ######################
  // Private
  // ######################

  void _applyScBuilders(Node<dynamic> node, {Scope? scope}) {
    scope ??= node.scope;

    for (final builder in scope.builders) {
      builder.applyToNode(node);
    }

    if (scope.parent != null) {
      _applyScBuilders(node, scope: scope.parent);
    }
  }
}
