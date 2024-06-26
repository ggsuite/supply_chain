// @license
// Copyright (c) 2019 - 2023 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:meta/meta.dart';
import 'package:supply_chain/supply_chain.dart';

/// A supplier delivers products to a node
typedef Supplier<T> = Node<T>;

/// A customer receives products to a node
typedef Customer<T> = Node<T>;

/// A worker is a node on the assembly line
typedef Worker<T> = Node<T>;

/// Produce delegate
typedef Produce<T> = T Function(
  List<dynamic> components,
  T previousProduct,
);

/// A node in a scope
class Node<T> {
  // ...........................................................................
  /// - [initialProduct]: The product delivered before [produce] is called the
  ///   first time
  /// - [produce]: A function producing the product and saving it in product.
  ///   Important: Call node.reportUpdate() after production.
  /// - [hasUpdates]: Is called after the product has been updated
  /// - [needsUpdates]: Is called when the product needs to be updated
  /// - [scope]: The scope the node belongs to
  /// - [key]: The key of the node
  /// - [cacheSize]: The number of items in the cache
  Node({
    required NodeBluePrint<T> bluePrint,
    required this.scope,
  })  : scm = scope.scm,
        _originalProduct = bluePrint.initialProduct,
        assert(bluePrint.key.isCamelCase),
        _bluePrint = bluePrint {
    _init();
  }

  // ...........................................................................
  /// Disposes the node
  void dispose() {
    _isDisposed = true;
    for (final d in _dispose.reversed) {
      d();
    }
    _dispose.clear();
  }

  /// Returns true if node is disposed
  bool get isDisposed => _isDisposed;

  // ...........................................................................
  /// Set back to initial state
  void reset() {
    if (_originalProduct == bluePrint.initialProduct) {
      return;
    }

    _originalProduct = bluePrint.initialProduct;
    scm.nominate(this);
  }

  // ...........................................................................
  /// Updates the node with a new bluePrint
  void update(NodeBluePrint<T> bluePrint) {
    final oldBluePrint = this.bluePrint;

    if (bluePrint == oldBluePrint) {
      return;
    }

    assert(bluePrint.key == this.bluePrint.key);

    // Update the bluePrint
    this._bluePrint = bluePrint;

    // If the produce function has changed, we need to produce again
    if (bluePrint.produce != oldBluePrint.produce) {
      scm.nominate(this);
    }
  }

  // ...........................................................................
  /// The configuration of this node
  NodeBluePrint<T> get bluePrint => _bluePrint;

  // ...........................................................................
  // Identification
  /// The key of the node
  String get key => bluePrint.key;

  /// The key of the node
  String get path => '${scope.path}.$key';

  /// Returns true, if this path matches the given path
  bool matchesPath(String path) => _matchesPath(path);

  /// The unique id of the node
  final int id = _idCounter++;

  /// Returns the key of the node
  @override
  String toString() {
    return key;
  }

  // ...........................................................................
  // Product

  /// The product of the node
  T get product => mockedProduct ?? insertResult ?? _originalProduct;

  /// Returns the original product not processed by inserts
  T get originalProduct => mockedProduct ?? _originalProduct;

  /// The product of the node
  set product(T v) {
    assert(
      bluePrint.produce == doNothing<T>,
      '$path:  Product can only be set if bluePrint.produce is doNothing',
    );
    _throwIfNotAllowed(v);
    _originalProduct = v;
    scm.nominate(this);
  }

  /// If mocked product is set, this product is returned
  set mockedProduct(T? t) {
    _mockedProduct = t;
    scm.nominate(this);
  }

  /// Returns the mocked product or null
  T? get mockedProduct => _mockedProduct;

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
  T _originalProduct;

  /// Produces the product.
  void produce({bool announce = true}) {
    assert(!isDisposed);

    final newProduct = bluePrint.produce(
      suppliers.map((s) => s.product).toList(),
      previousProduct,
    );

    _throwIfNotAllowed(newProduct);

    _originalProduct = newProduct;

    // If this node is the last insert in the chain,
    // write the product into the host's insertResult
    if (this.bluePrint.isInsert) {
      final insert = this as Insert<T>;
      if (insert.isLastInsert) {
        insert.host.insertResult = newProduct;
      }
    }

    // Announce
    if (announce) {
      scm.hasNewProduct(this);
    }
  }

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

  /// Get suppliers of the node of a given depth
  Iterable<Node<dynamic>> deepSuppliers({int depth = 1}) {
    if (depth < 0) depth = 100000;

    if (depth == 0) {
      return [];
    }

    final result = <Node<dynamic>>[...suppliers];

    for (final supplier in suppliers) {
      result.addAll(supplier.deepSuppliers(depth: depth - 1));
    }
    return result;
  }

  // ...........................................................................
  // Customers

  /// The customers of the node
  Iterable<Node<dynamic>> get customers => _customers;

  /// Add a customer to the node
  void addCustomer(Customer<dynamic> customer) => _addCustomer(customer);

  /// Remove a customer from the node
  void removeCustomer(Customer<dynamic> customer) => _removeCustomer(customer);

  /// Get suppliers of the node of a given depth
  Iterable<Node<dynamic>> deepCustomers({int depth = 1}) {
    if (depth == 0) {
      return [];
    }

    final result = <Node<dynamic>>[...customers];

    for (final customer in customers) {
      result.addAll(customer.deepCustomers(depth: depth - 1));
    }
    return result;
  }

  // ...........................................................................
  /// Insert uses this method to add itself to the host node
  @protected
  void addInsert(Insert<T> insert, {int? index}) {
    _inserts.insert(index ?? _inserts.length, insert);
  }

  /// Insert uses this method to remove itself from the host node
  @protected
  void removeInsert(Insert<T> insert) {
    _inserts.remove(insert);
  }

  /// The value return by this method is forwarded to the produce method
  @protected
  T get previousProduct => originalProduct;

  @protected

  /// The last insert will write it's result into this variable
  T? insertResult;

  /// Clears all inserts
  void clearInserts() {
    for (final insert in [..._inserts]) {
      insert.dispose();
    }
  }

  /// Returns the insert with the key or null when not found
  Node<T>? insert(String key) {
    for (final insert in _inserts) {
      if (insert.key == key) {
        return insert;
      }
    }
    return null;
  }

  /// Returns the list of insert nodes
  Iterable<Insert<T>> get inserts => _inserts;

  // ...........................................................................
  // Timeouts

  /// Is set to true if production times out
  bool isTimedOut = false;

  /// Milliseconds showing the production start time.
  Duration productionStartTime = Duration.zero;

  // ...........................................................................
  /// Example node for test purposes
  static Node<int> example({
    NodeBluePrint<int>? bluePrint,
    Scope? scope,
    String? key,
  }) {
    scope ??= Scope.example(scm: Scm.testInstance);
    bluePrint ??= NodeBluePrint.example(key: key);

    final result = Node<int>(
      bluePrint: bluePrint,
      scope: scope,
    );

    // Realtime nodes will produce immediately
    result.ownPriority = Priority.realtime;

    return result;
  }

  // ######################
  // Private
  // ######################

  // ...........................................................................

  /// Reset Id counter for tests
  static void testResetIdCounter() => _idCounter = 0;

  static int _idCounter = 0;

  // ...........................................................................
  // Init & Dispose
  void _init() {
    _initScope();
    _initScm();
  }

  // ...........................................................................
  void _initScm() {
    scm.addNode(this);
    scm.needsInitSuppliers(this);
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
      scope.removeNode(this.key);
    });
  }

  // ...........................................................................
  /// The supply chain manager
  final Scm scm;

  /// The chain this node belongs to
  final Scope scope;

  /// The common scope of two nodes
  Scope commonParent(Node<dynamic> other) {
    return scope.commonParent(other.scope);
  }

  // ...........................................................................
  // Graph
  /// Save the graph to a file
  ///
  /// The format can be
  /// bmp canon cgimage cmap cmapx cmapx_np dot dot_json eps exr fig gd gd2 gif
  /// gv icns ico imap imap_np ismap jp2 jpe jpeg jpg json json0 kitty kittyz
  /// mp pct pdf pic pict plain plain-ext png pov ps ps2 psd sgi svg svgz tga
  /// tif tiff tk vrml vt vt-24bit wbmp webp xdot xdot1.2 xdot1.4 xdot_json
  Future<void> writeImageFile(
    String path, {
    int supplierDepth = 0,
    int customerDepth = 0,
    List<Node<dynamic>>? highlightedNodes,
    List<Scope>? highlightedScopes,
  }) async {
    const graph = Graph();

    final dot = this.dot(
      supplierDepth: supplierDepth,
      customerDepth: customerDepth,
      highlightedNodes: highlightedNodes,
      highlightedScopes: highlightedScopes,
    );
    await graph.writeImageFile(path: path, dot: dot);
  }

  // ...........................................................................
  /// Returns a graph that can be turned into svg using graphviz
  String dot({
    int supplierDepth = 0,
    int customerDepth = 0,
    List<Node<dynamic>>? highlightedNodes,
    List<Scope>? highlightedScopes,
  }) {
    const graph = Graph();
    final tree = graph.treeForNode(
      node: this,
      supplierDepth: supplierDepth,
      customerDepth: customerDepth,
      highlightedNodes: highlightedNodes ?? [this],
      highlightedScopes: highlightedScopes,
    );
    final dot = graph.dot(tree: tree);
    return dot;
  }

  // ######################
  // Private
  // ######################

  // ...........................................................................
  final List<void Function()> _dispose = [];

  bool _isDisposed = false;

  T? _mockedProduct;

  // ...........................................................................
  final List<Insert<T>> _inserts = [];

  // ...........................................................................
  NodeBluePrint<T> _bluePrint;

  // ...........................................................................
  Priority _ownPriority = Priority.frame;

  // ...........................................................................
  final List<Supplier<dynamic>> _suppliers = [];
  final List<Customer<dynamic>> _customers = [];

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
    if (!isDisposed) {
      scm.nominate(this);
    }
  }

  // ...........................................................................
  void _addCustomer(Customer<dynamic> customer) {
    if (_customers.contains(customer)) {
      return;
    }

    _customers.add(customer);
    customer.addSupplier(this);
  }

  // ...........................................................................
  void _removeCustomer(Customer<dynamic> customer) {
    if (!_customers.contains(customer)) {
      return;
    }

    _customers.remove(customer);
    customer.removeSupplier(this);
  }

  // ...........................................................................
  // Tick & Animation
  bool _isAnimated = false;

  // ...........................................................................
  bool _matchesPath(String path) {
    if (this.path == path) {
      return true;
    }

    final parts = path.split('.');
    final key = parts.last;
    if (key != this.key) {
      return false;
    }

    parts.removeLast();
    return scope.matchesPathArray(parts);
  }

  // ...........................................................................
  void _throwIfNotAllowed(T product) {
    // Check, if the new product is allowed
    if (bluePrint.allowedProducts.isNotEmpty) {
      if (!bluePrint.allowedProducts.contains(product)) {
        throw ArgumentError('The product $product '
            'is not in the list of allowed products '
            '[${bluePrint.allowedProducts.join(', ')}].');
      }
    }
  }
}

/// Provides a deeply configured node sructure
class ButterFlyExample {
  /// Constructor
  ButterFlyExample({bool withScopes = false}) {
    final scope = Scope.example(scm: Scm.example(), key: 'butterFly');

    if (withScopes) {
      scope.mockContent({
        'level3': {
          's111': 's111',
          'level2': {
            's11': 's11',
            's10': 's10',
            's01': 's01',
            's00': 's00',
            'level1': {
              's1': 's1',
              's0': 's0',
              'level0': {
                'x': 'x',
              },
              'c0': 'c0',
              'c1': '1',
            },
            'c00': 'c00',
            'c01': 'c01',
            'c10': 'c10',
            'c11': 'c11',
          },
          'c111': 'c111',
        },
      });
    } else {
      scope.mockContent({
        's111': 's111',
        's11': 's11',
        's10': 's10',
        's01': 's01',
        's00': 's00',
        's1': 's1',
        's0': 's0',
        'x': 'x',
        'c0': 'c0',
        'c1': '1',
        'c00': 'c00',
        'c01': 'c01',
        'c10': 'c10',
        'c11': 'c11',
        'c111': 'c111',
      });
    }

    s111 = scope.findNode<String>('s111')!;
    s11 = scope.findNode<String>('s11')!;
    s10 = scope.findNode<String>('s10')!;
    s01 = scope.findNode<String>('s01')!;
    s00 = scope.findNode<String>('s00')!;
    s1 = scope.findNode<String>('s1')!;
    s0 = scope.findNode<String>('s0')!;
    x = scope.findNode<String>('x')!;
    c0 = scope.findNode<String>('c0')!;
    c1 = scope.findNode<String>('c1')!;
    c00 = scope.findNode<String>('c00')!;
    c01 = scope.findNode<String>('c01')!;
    c10 = scope.findNode<String>('c10')!;
    c11 = scope.findNode<String>('c11')!;
    c111 = scope.findNode<String>('c111')!;

    allNodes = [
      s111,
      s11,
      s10,
      s01,
      s00,
      s1,
      s0,
      x,
      c0,
      c1,
      c00,
      c01,
      c10,
      c11,
      c111,
    ];

    s11.addSupplier(s111);
    s1.addSupplier(s11);
    s1.addSupplier(s10);
    s0.addSupplier(s01);
    s0.addSupplier(s00);
    x.addSupplier(s1);
    x.addSupplier(s0);
    x.addCustomer(c0);
    x.addCustomer(c1);
    c0.addCustomer(c00);
    c0.addCustomer(c01);
    c1.addCustomer(c10);
    c1.addCustomer(c11);
    c11.addCustomer(c111);

    if (withScopes) {
      level0 = scope.findScope('level0')!;
      level1 = scope.findScope('level1')!;
      level2 = scope.findScope('level2')!;
      level3 = scope.findScope('level3')!;

      allScopes = [level0, level1, level2, level3, scope];
    } else {
      allScopes = [];
    }
  }

  // ...........................................................................

  /// s111
  late final Node<String> s111;

  /// s11
  late final Node<String> s11;

  /// s10
  late final Node<String> s10;

  /// s01
  late final Node<String> s01;

  /// s00
  late final Node<String> s00;

  /// s1
  late final Node<String> s1;

  /// s0
  late final Node<String> s0;

  /// x
  late final Node<String> x;

  /// c0
  late final Node<String> c0;

  /// c1
  late final Node<String> c1;

  /// c00
  late final Node<String> c00;

  /// c01
  late final Node<String> c01;

  /// c10
  late final Node<String> c10;

  /// c11
  late final Node<String> c11;

  /// c111
  late final Node<String> c111;

  /// All nodeså
  late final List<Node<dynamic>> allNodes;

  // ...........................................................................

  /// level0
  late final Scope level0;

  /// level1
  late final Scope level1;

  /// level2
  late final Scope level2;

  /// level3
  late final Scope level3;

  /// A list of all scopes
  late final List<Scope> allScopes;
}

// #############################################################################
/// Creates a house with walls
class TriangleExample {
  /// Constructor
  TriangleExample() {
    triangle = Scope.example(scm: Scm.example(), key: 'triangle');
    triangle.mockContent({
      'top': 0,
      'left': {
        'left': 0,
      },
      'right': {
        'right': 0,
      },
    });

    topNode = triangle.findNode<int>('top')!;
    leftNode = triangle.findNode<int>('left')!;
    rightNode = triangle.findNode<int>('right')!;

    topScope = triangle;
    leftScope = triangle.findScope('left')!;
    rightScope = triangle.findScope('right')!;

    topNode.addCustomer(leftNode);
    topNode.addCustomer(rightNode);
    leftNode.addCustomer(rightNode);

    allNodes = [topNode, leftNode, rightNode];
    allScopes = [topScope, leftScope, rightScope];
  }

  /// The house scope
  late final Scope triangle;

  /// The top node
  late final Node<int> topNode;

  /// The left node
  late final Node<int> leftNode;

  /// The right node
  late final Node<int> rightNode;

  /// The top scope
  late final Scope topScope;

  /// The left scope
  late final Scope leftScope;

  /// The right scope
  late final Scope rightScope;

  /// All nodes
  late final List<Node<dynamic>> allNodes;

  /// All scopes
  late final List<Scope> allScopes;
}
