// @license
// Copyright (c) 2019 - 2023 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'names.dart';
import 'priority.dart';
import 'scm.dart';
import 'scm_node_interface.dart';
import 'scope.dart';
import 'tools.dart';

/// A supplier delivers products to a node
typedef Supplier<T> = Node<T>;

/// A customer receives products to a node
typedef Customer<T> = Node<T>;

/// A worker is a node on the assembly line
typedef Worker<T> = Node<T>;

/// Produce delegate
typedef Produce<T> = void Function(Node<T>);

/// A node in the supply chain
class Node<T> {
  // ...........................................................................

  /// - [initialProduct]: The product delivered before [produce] is called the
  ///   first time
  /// - [produce]: A function producing the product and saving it in product.
  ///   Important: Call node.reportUpdate() after production.
  /// - [hasUpdates]: Is called after the product has been updated
  /// - [needsUpdates]: Is called when the product needs to be updated
  Node({
    required T initialProduct,
    required Produce<T> produce,
    required this.scope,
    String? name,
  })  : scm = scope.scm,
        product = initialProduct,
        assert(name == null || name.isPascalCase),
        name = name ?? nextName,
        _produce = produce {
    _init();
  }

  // ...........................................................................
  /// Disposes the node
  void dispose() {
    for (final d in _dispose.reversed) {
      d();
    }
  }

  // ...........................................................................
  // Identification
  /// The name of the node
  final String name;

  /// Returns the name of the node
  @override
  String toString() {
    return name;
  }

  // ...........................................................................
  // Animation

  /// Returns true if node is animated
  bool get isAnimated => _isAnimated;

  /// Assign true if node is animated. Node will be nominated on every frame.
  set isAnimated(bool v) {
    if (_isAnimated == v) {
      return;
    }

    _isAnimated = v;

    if (v) {
      scm.animateNode(this);
    } else {
      scm.deanimateNode(this);
    }
  }

  // ...........................................................................
  // Preparation

  /// Returns true if suppliers or internal conditions have changed
  bool get needsUpdate {
    return suppliersHash != _previousSupplierHash;
  }

  /// Returns true if node and its customers need to be prepared for production
  bool needsPreparation() {
    /// If new priority is higher then current one, a new preparation is needed
    return !isStaged;
  }

  /// Prepares the node for production with a given priority
  void prepare() {
    this.isStaged = true;
  }

  /// Returns true, if node is not staged
  bool get isReady => !isStaged;

  /// Is ready to produce when all suppliers are ready
  bool get isReadyToProduce {
    for (final supplier in suppliers) {
      if (!supplier.isReady) {
        return false;
      }
    }
    return true;
  }

  // ...........................................................................
  // Priority

  /// The node's own priority.
  Priority get ownPriority => _ownPriority;

  /// Changes node's own priority
  set ownPriority(Priority p) {
    _ownPriority = p;
    scm.priorityHasChanged(this);
  }

  /// SCM uses this to assign the highest customer priority
  Priority? customerPriority;

  /// The used priority. Is the highest priority of node and its customers
  Priority get priority =>
      (customerPriority != null && customerPriority!.value > ownPriority.value)
          ? customerPriority!
          : ownPriority;

  // ...........................................................................
  // Production

  /// The product produced by this node
  T product;

  /// Produces the product.
  void produce() => _produce(this);

  /// Returns true, if node is staged for production
  bool isStaged = false;

  /// Finalizes production
  void finalizeProduction() {
    this.isStaged = false;
  }

  // ...........................................................................
  // Suppliers

  /// The suppliers of the node
  Iterable<Node<dynamic>> get suppliers => _suppliers;

  /// Add a supplier to the node
  void addSupplier(Supplier<dynamic> supplier) => _addSupplier(supplier);

  /// Remove a supplier from the node
  void removeSupplier(Supplier<dynamic> supplier) => _removeSupplier(supplier);

  /// Calculates a hash for all supplier's products
  int get suppliersHash {
    int result = 0;
    for (final supplier in suppliers) {
      result = result ^ supplier.product.hashCode;
    }

    return result;
  }

  // ...........................................................................
  // Customers

  /// The customers of the node
  Iterable<Node<T>> get customers => _customers;

  /// Add a customer to the node
  void addCustomer(Customer<T> customer) => _addCustomer(customer);

  /// Remove a customer from the node
  void removeCustomer(Customer<T> customer) => _removeCustomer(customer);

  // ...........................................................................
  // Timeouts

  /// Is set to true if production times out
  bool isTimedOut = false;

  /// Milliseconds showing the production start time.
  Duration productionStartTime = Duration.zero;

  // ######################
  // Private
  // ######################

  // ...........................................................................
  // Init & Dispose
  void _init() {
    _initScope();
    _initScm();
  }

  // ...........................................................................
  void _initScm() {
    scm.addNode(this);
    _dispose.add(() {
      scm.removeNode(this);

      // Cleanup suppliers
      for (final supplier in [...suppliers]) {
        removeSupplier(supplier);
      }

      // Cleanup customers
      for (final customer in [...customers]) {
        removeCustomer(customer);
      }
    });
  }

  // ...........................................................................
  void _initScope() {
    scope.addNode(this);
    _dispose.add(() {
      scope.removeNode(this);
    });
  }

  // ...........................................................................
  final List<void Function()> _dispose = [];

  // ...........................................................................
  final Produce<T> _produce;
  final int _previousSupplierHash = 1829307102703;
  Priority _ownPriority = Priority.frame;

  // ...........................................................................
  /// The supply chain manager
  final ScmNodeInterface scm;

  /// The scope this node belongs to
  final Scope scope;

  // ...........................................................................
  final List<Supplier<dynamic>> _suppliers = [];
  final List<Supplier<T>> _customers = [];

  // ...........................................................................
  void _addSupplier(Supplier<dynamic> supplier) {
    // Supplier<T> already added? Do nothing.
    if (_suppliers.contains(supplier)) {
      return;
    }

    // Add supplier to list of suppliers
    _suppliers.add(supplier);

    // This producer becomes a customer of its supplier
    supplier.addCustomer(this);

    // Because we have new dependencies, a rebuild is needed
    scm.nominate(this);
  }

  // ...........................................................................
  void _removeSupplier(Supplier<dynamic> supplier) {
    if (!_suppliers.contains(supplier)) {
      return;
    }

    _suppliers.remove(supplier);
    supplier.removeCustomer(this);
    scm.nominate(this);
  }

  // ...........................................................................
  void _addCustomer(Customer<T> customer) {
    if (_customers.contains(customer)) {
      return;
    }

    _customers.add(customer);
    customer.addSupplier(this);
  }

  // ...........................................................................
  void _removeCustomer(Customer<T> customer) {
    if (!_customers.contains(customer)) {
      return;
    }

    _customers.remove(customer);
    customer.removeSupplier(this);
  }

  // ...........................................................................
  // Tick & Animation
  bool _isAnimated = false;
}

// #############################################################################
/// Example node for test purposes
Node<int> exampleNode({
  int initialProduct = 0,
  void Function(Node<int>)? produce,
  Scope? scope,
  String? name,
}) {
  scope ??= Scope.example(scm: Scm.testInstance);

  final result = Node<int>(
    name: name,
    initialProduct: initialProduct,
    produce: produce ??
        (Node<int> n) {
          n.product++;
          n.scm.hasNewProduct(n);
        },
    scope: scope,
  );

  // Realtime nodes will produce immediately
  result.ownPriority = Priority.realtime;

  return result;
}
