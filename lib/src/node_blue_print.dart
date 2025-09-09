// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:collection/collection.dart';
import 'package:supply_chain/supply_chain.dart';

/// Produce delegate that does nothing
T doNothing<T>(List<dynamic> components, T previousProduct) => previousProduct;

/// A function that parses a json map into a product of type T
typedef FromJson<T> = T Function(Map<String, dynamic> json);

/// A function that parses a string into a product of type T
typedef FromString<T> = T Function(String str);

/// A function that serializes a product of type T into a json value
typedef ToJson<T> = dynamic Function(T data);

// .............................................................................
/// Forwards the node from
NodeBluePrint<T> nbp<T>({
  required List<String> from,
  required String to,
  required T init,
  Produce<T>? produce,
}) => NodeBluePrint(
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
    List<String> smartMaster = const [],
    this.canBeSmart = true,
    T Function(Map<String, dynamic> json)? fromJson,
  }) : produce = produce ?? doNothing<T>,
       _smartMaster = smartMaster;

  /// Maps a supplier to a different key
  factory NodeBluePrint.map({
    required String supplier,
    required String toKey,
    required T initialProduct,
    T Function(Map<String, dynamic> json)? fromJson,
  }) {
    return NodeBluePrint(
      key: toKey,
      initialProduct: initialProduct,
      suppliers: [supplier],
      produce: (components, previous) => components.first as T,
      fromJson: fromJson,
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

  /// If [canBeSmart] is set to false this node will not be a smart node,
  /// also if it is placed within a smart scope
  /// or if it has a smart master path set.
  final bool canBeSmart;

  /// If [smartMaster] is set this node will automatically connect to the
  /// smartMaster and take over it's values once it is available.
  List<String> get smartMaster => canBeSmart ? _smartMaster : const [];

  // ...........................................................................
  /// An example instance for test purposes
  static NodeBluePrint<int> example({String? key, Produce<int>? produce}) =>
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

    final result = Node<T>(bluePrint: this, scope: scope, owner: owner);

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
    return Insert<T>(bluePrint: this, host: host, index: index, scope: scope);
  }

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) {
      return false;
    }

    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }

    return true;
  }

  // ...........................................................................
  /// Create a modified copy of the blue print
  NodeBluePrint<T> copyWith({
    T? initialProduct,
    String? key,
    Iterable<String>? suppliers,
    Produce<T>? produce,
    bool? canBeSmart,
    List<String>? smartMaster,
  }) {
    if ((initialProduct == null || initialProduct == this.initialProduct) &&
        (key == null || key == this.key) &&
        (suppliers == null || suppliers == this.suppliers) &&
        (produce == null || produce == this.produce) &&
        (canBeSmart == null || canBeSmart == this.canBeSmart) &&
        (smartMaster == null ||
            smartMaster == this.smartMaster ||
            _listEquals(smartMaster, this.smartMaster) ||
            (smartMaster.isEmpty && this.smartMaster.isEmpty))) {
      return this;
    }

    return NodeBluePrint<T>(
      initialProduct: initialProduct ?? this.initialProduct,
      key: key ?? this.key,
      suppliers: suppliers ?? this.suppliers,
      produce: produce ?? this.produce,
      canBeSmart: canBeSmart ?? this.canBeSmart,
      smartMaster: smartMaster ?? _smartMaster,
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

  /// Converts the product into a json value
  dynamic toJson(T product) {
    if (product is int ||
        product is double ||
        product is num ||
        product is String ||
        product is bool ||
        product is Map ||
        product is List) {
      return product;
    } else {
      try {
        return (product as dynamic).toJson();
      } on NoSuchMethodError catch (_) {
        final serializer = _jsonSerializers[T.runtimeType];
        if (serializer != null) {
          return serializer(product);
        } else {
          throw Exception(
            [
              'No serializer registered for type $T.',
              'Either:',
              ' - implement $T.toJson or',
              ' - register a json serializer using '
                  'NodeBluePrint.addJsonSerializer<$T>(serializer)',
            ].join('\n'),
          );
        }
      } catch (e) {
        rethrow;
      }
    }
  }

  /// Set a json converter here to be able to convert json into the product
  static void addJsonParser<T>(FromJson<T> parseJson) {
    final existing = _jsonParsers[T];
    if (existing != null && existing != parseJson) {
      throw Exception(
        'A different json parser for type $T is already registered.',
      );
    }

    _jsonParsers[T] = parseJson;
  }

  /// Removes a json parser for the given type
  static void removeJsonParser<T>() {
    _jsonParsers.remove(T.runtimeType);
  }

  /// Set a string converter here to be able to convert json into the product
  static void addStringParser<T>(FromString<T> parseString) {
    final existing = _stringParsers[T];
    if (existing != null && existing != parseString) {
      throw Exception(
        'A different string parser for type $T is already registered.',
      );
    }

    _stringParsers[T] = parseString;
  }

  /// Clears all json parsers. Useful for testing purposes.
  static void clearParsers() {
    _jsonParsers.clear();
    _stringParsers.clear();
  }

  /// Set a json converter here to be able to convert json into the product
  static void addJsonSerializer<T>(ToJson<T> toJson) {
    final rtt = T.runtimeType;
    if (!_jsonSerializers.containsKey(rtt)) {
      _jsonSerializers[rtt] = toJson;
    }
  }

  /// Converts json into the product
  T fromJson(dynamic value) {
    // value matches the type T
    if (value is T) {
      return value;
    }
    // Value is a map
    else if (value is Map<String, dynamic> && initialProduct is Map) {
      return castMap(value);
    }

    if (value is Map<String, dynamic>) {
      final parseJson = _jsonParsers[T];
      if (parseJson != null) {
        return parseJson(value) as T;
      } else {
        throw Exception(
          'Please register a json parser using '
          'NodeBluePrint.addJsonParser<$T>(parser).',
        );
      }
    }
    // Value is a string
    else if (value is String) {
      final parseString = _stringParsers[T];
      if (parseString != null) {
        return parseString(value) as T;
      } else {
        throw Exception(
          'Please register a string parser using '
          'NodeBluePrint.addStringParser<$T>(parser).',
        );
      }
    }
    // Otherwise throw
    else {
      throw Exception(
        'Value "$value" is of type ${value.runtimeType}.\n'
        'But it must be either a primitive or a map.',
      );
    }
  }

  /// Casts a map to a specific map type T
  T castMap(Map<String, dynamic> map) {
    assert(initialProduct is Map);

    // Remove hash
    if (map.containsKey('_hash')) {
      map = {...map}..remove('_hash');
    }

    // If map has the same type as T, return it
    if (map is T) {
      return map as T;
    }

    // Handle maps of various types
    if (T == Map<String, int>) {
      return _cast<int>(map) as T;
    } else if (T == Map<String, double>) {
      return _cast<double>(map) as T;
    } else if (T == Map<String, num>) {
      return _cast<num>(map) as T;
    } else if (T == Map<String, bool>) {
      return _cast<bool>(map) as T;
    } else if (T == Map<String, String>) {
      return _cast<bool>(map) as T;
    }

    return map as T;
  }

  Map<String, S> _cast<S>(Map<String, dynamic> map) {
    try {
      if (S == double) {
        map = map.map<String, double>(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        );
        return map as Map<String, S>;
      }

      final casted = map.cast<String, S>();
      casted.values.toList();
      return casted;
    } catch (_) {
      throw Exception(
        [
          'Cannot cast ${map.runtimeType} to $S.',
          '  - Make sure NodeBluePrint with key "$key" becomes '
              'either a Node of type',
          '    - Map<String, $S> or of type',
          '    - Map<String, dynamic> containing only $S values',
        ].join('\n'),
      );
    }
  }

  // ######################
  // Private
  // ######################

  static final Map<Type, FromString<dynamic>> _stringParsers = {};
  static final Map<Type, FromJson<dynamic>> _jsonParsers = {};
  static final Map<Type, dynamic> _jsonSerializers = {};

  final List<String> _smartMaster;

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
