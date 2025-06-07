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
typedef Produce<T> = T Function(List<dynamic> components, T previousProduct);

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
  /// - [owner]: The owner of the node
  Node({
    required NodeBluePrint<T> bluePrint,
    required this.scope,
    this.isInsert = false,
    Owner<Node<dynamic>>? owner,
  }) : scm = scope.scm,
       _owner = owner,
       _originalProduct = bluePrint.initialProduct,
       assert(bluePrint.key.isCamelCase) {
    _bluePrints.add(bluePrint);
    _init();
  }

  /// Allows to listen to 'on.change'
  static bool onChangeEnabled = false;

  /// Allows to listen to 'on.recursiveChange'
  static bool onRecursiveChangeEnabled = false;

  // ...........................................................................
  /// Disposes the node
  /// - All suppliers are removed: node will not update anymore
  /// - Node is marked as disposed
  /// - When node has no customers anymore it will also be erased
  /// - As long the node has still customers it remains in the node hiearchy
  ///   to not break the chain
  void dispose() {
    _owner?.willDispose?.call(this);
    _isDisposed = true;

    // Remove all suppliers
    for (final supplier in [...suppliers]) {
      _removeSupplier(supplier);
    }

    // Tell Scm to update smartNodes
    scm.updateSmartNodes(this);

    // Mute suppliers in the bluePrint
    if (bluePrint.suppliers.isNotEmpty && !isSmartNode) {
      final muted = bluePrint.copyWith(produce: doNothing, suppliers: []);
      addBluePrint(muted);
    }

    // Add the node to disposed.nodes
    if (customers.isNotEmpty) {
      scm.disposedItems.addNode(this);
    }
    // Erase the node if it should not have customers relying on it
    else {
      _erase();
    }

    _owner?.didDispose?.call(this);
  }

  // ...........................................................................
  /// Erases the node
  void _erase() {
    _owner?.willErase?.call(this);
    assert(customers.isEmpty);
    assert(isDisposed);

    assert(scope.node<T>(key) == this || scope.node<T>(key) == null);
    scope.removeNode(this.key);
    scm.removeNode(this);
    scm.disposedItems.removeNode(this);

    _isErased = true;
    _owner?.didErase?.call(this);
  }

  /// Returns true if node is initialized
  bool get isInitialized => _isInitialized;

  /// Returns true if node is erased
  bool get isErased => _isErased;

  /// Returns true if the node is disposed
  bool get isDisposed => _isDisposed;

  /// Returns true if node is a smartNode
  bool get isSmartNode => smartMaster.isNotEmpty;

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
  /// ScBuilders use this method to replace the present blue print
  void addBluePrint(NodeBluePrint<T> bluePrint) {
    // Replacing blueprints is not allowed for smartNode blueprints
    assert(!isSmartNode);
    _addBluePrint(bluePrint);
  }

  /// ScBuilders use this method to remove a formerly added blue print
  void removeBluePrint(NodeBluePrint<T> bp) {
    if (!_bluePrints.contains(bp)) {
      throw ArgumentError('The blue print "${bp.key}" does not exist.');
    }

    if (_bluePrints.first == bp) {
      throw ArgumentError('Cannot remove last bluePrint.');
    }

    _bluePrints.remove(bp);

    if (!isDisposed) {
      reset();
      scm.nominate(this);
    }
  }

  // ...........................................................................
  /// Called by SCM to update smartNodes
  void addSmartNodeReplacement(NodeBluePrint<T> smartNode) {
    assert(isSmartNode);
    assert(allBluePrints.length == 1);
    _addBluePrint(smartNode);
  }

  // ...........................................................................
  /// Called by SCM to update smartNodes
  void resetSmartNodeReplacements() {
    assert(isSmartNode);
    assert(allBluePrints.length <= 2);
    if (allBluePrints.length == 2) {
      removeBluePrint(allBluePrints.last);
    }
  }

  // ...........................................................................
  /// The configuration of this node
  NodeBluePrint<T> get bluePrint => _bluePrint;

  // ...........................................................................
  /// Returns all stacked blue prints
  List<NodeBluePrint<T>> get allBluePrints => _bluePrints;

  // ...........................................................................
  // Identification
  /// The key of the node
  String get key => bluePrint.key;

  /// The key of the node
  String get path => '${scope.path}.$key';

  /// Returns true, if this path matches the given path
  bool matchesPath(String path) => _matchesPath(path.split('.'));

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
    if (!_suppliersAreInitialized) {
      return false;
    }

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

  final List<dynamic> _products = [];

  /// The product produced by this node
  T _originalProduct;

  /// Produces the product.
  void produce({bool announce = true, bool triggerOnChange = true}) {
    assert(!isDisposed);
    assert(_suppliersAreInitialized);
    if (_mockedProduct != null) {
      if (announce) {
        scm.hasNewProduct(this);
      }
      return;
    }

    int i = 0;
    for (final supplier in suppliers) {
      _products[i] = supplier.product;
      i++;
    }

    final newProduct = bluePrint.produce(_products, previousProduct);

    _throwIfNotAllowed(newProduct);

    _originalProduct = newProduct;

    // If this node is the last insert in the chain,
    // write the product into the host's insertResult
    if (this.isInsert) {
      final insert = this as Insert<T>;
      if (insert.isLastInsert) {
        insert.host.insertResult = newProduct;
      }
    }

    // Announce
    if (announce) {
      scm.hasNewProduct(this);
    }

    if (triggerOnChange) {
      _triggerOnChange();
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

  /// Call this method to update the suppliers again
  void needsInitSuppliers() {
    _clearSuppliers();
  }

  /// Is called by SCM to initialize the suppliers
  void initSuppliers(Map<String, Node<dynamic>> newSuppliers) {
    _detectCircularDependencies(this, newSuppliers.values, [this]);

    // Make sure the keys match the blue print's suppliers
    final s = bluePrint.suppliers;
    for (var supplierKey in newSuppliers.keys) {
      assert(s.contains(supplierKey) || s.contains('..$supplierKey'));
    }

    // Reset old suppliers
    for (final supplier in [...suppliers]) {
      _removeSupplier(supplier); // coverage:ignore-line
    }

    // Reset old suppliers
    for (final supplier in newSuppliers.values) {
      _addOrReplaceSupplier(supplier);
    }

    // Enlarge or shrink _products
    _products.length = suppliers.length;

    _suppliersAreInitialized = true;
  }

  // ...........................................................................
  // Customers

  /// The customers of the node
  Iterable<Node<dynamic>> get customers => _customers;

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
  /// Returns the master node for the smart node
  Node<T>? findSmartMaster() {
    assert(isSmartNode);
    final masterPath = this.smartMaster;
    Scope? parent = scope;
    while (parent != null) {
      final foundMaster = parent.findDirectChildNode<T>(masterPath);
      if (foundMaster != null &&
          !foundMaster.isDisposed &&
          foundMaster != this &&
          foundMaster.scope != this.scope) {
        return foundMaster;
      }
      parent = parent.parent;
    }
    return null;
  }

  // ...........................................................................
  /// Returns true if this node could be the master of the other node
  bool couldBeMasterOf(Node<dynamic> smartNode) {
    if (smartNode.isSmartNode == false) {
      return false;
    }

    // Meta nodes cannot be master nodes currently
    if (isMetaNode) {
      return false;
    }

    if (!_matchesPath(smartNode.smartMaster)) {
      return false;
    }

    return true;
  }

  // ...........................................................................
  /// Returns the smart master path of this node or an empty path if this node
  /// is not a smart node.
  List<String> get smartMaster {
    /// Meta nodes are not smart nodes
    if (isMetaNode) {
      return const [];
    }

    /// If this node has a blue print that defines a smart master,
    /// return the smart master defined by the blue print
    final bp = allBluePrints.first;
    if (bp.smartMaster.isNotEmpty) {
      return bp.smartMaster;
    }

    /// Otherwise check, if the node is contained within a smart scope.
    final scopeSmartMaster = scope.smartMaster;
    if (scopeSmartMaster.isNotEmpty) {
      return [...scopeSmartMaster, key];
    }

    /// Return an empty array otherwise
    return const [];
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

  /// Returns if node is an insert
  final bool isInsert;

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
  /// Returns true if the node is a meta node
  bool get isMetaNode => scope.isMetaScope;

  // ...........................................................................
  /// Example node for test purposes
  static Node<int> example({
    NodeBluePrint<int>? bluePrint,
    Scope? scope,
    String? key,
  }) {
    scope ??= Scope.example(scm: Scm.testInstance);
    bluePrint ??= NodeBluePrint.example(key: key);

    final result = Node<int>(bluePrint: bluePrint, scope: scope);

    // Realtime nodes will produce immediately
    result.ownPriority = Priority.realtime;

    return result;
  }

  // ...........................................................................
  /// Returns the all onChange meta nodes depending on this node
  Iterable<Node<dynamic>> get _onChangeNodes {
    if (this.isMetaNode) {
      return const [];
    }

    final result = <Node<dynamic>>[];

    // Add the onChange node of the own scope
    if (onChangeEnabled) {
      result.add(scope.onChange!);
    }

    // Add onChangeRecursive of this node and it's parents
    if (onRecursiveChangeEnabled) {
      Scope? parent = this.scope;
      while (parent != null) {
        result.add(parent.onChangeRecursive!);
        parent = parent.parent;
      }
    }

    return result;
  }

  // ...........................................................................
  void _triggerOnChange() {
    if (!onChangeEnabled && !onRecursiveChangeEnabled) {
      return;
    }

    for (final node in _onChangeNodes) {
      scm.nominate(node);
    }
  }

  // ######################
  // Private
  // ######################

  // ...........................................................................
  final Owner<Node<dynamic>>? _owner;
  late bool _suppliersAreInitialized;
  bool _isInitialized = false;

  // ...........................................................................
  /// Reset Id counter for tests
  static void testResetIdCounter() => _idCounter = 0;

  static int _idCounter = 0;

  // ...........................................................................
  // Init & Dispose
  void _init() {
    _suppliersAreInitialized = bluePrint.suppliers.isEmpty;
    _initScope();
    _initScm();
    _isInitialized = true;
  }

  // ...........................................................................
  void _initScm() {
    scm.addNode(this);
    needsInitSuppliers();
    scm.updateSmartNodes(this);
  }

  // ...........................................................................
  void _initScope() {
    scope.addNode(this);
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
    int dpi = Graph.defaultDpi,
    bool write2x = false,
  }) async {
    final dot = this.dot(
      supplierDepth: supplierDepth,
      customerDepth: customerDepth,
      highlightedNodes: highlightedNodes,
      highlightedScopes: highlightedScopes,
    );
    await GraphToDot.writeImageFile(
      path: path,
      dot: dot,
      dpi: dpi,
      write2x: write2x,
    );
  }

  // ...........................................................................
  /// Returns a graph that can be turned into svg using graphviz
  String dot({
    int supplierDepth = 0,
    int customerDepth = 0,
    List<Node<dynamic>>? highlightedNodes,
    List<Scope>? highlightedScopes,
    int dpi = Graph.defaultDpi,
    bool write2x = false,
  }) {
    const graph = Graph();
    final tree = graph.treeForNode(
      node: this,
      supplierDepth: supplierDepth,
      customerDepth: customerDepth,
      highlightedNodes: highlightedNodes ?? [this],
      highlightedScopes: highlightedScopes,
    );
    final dot = graph.dot(tree: tree, dpi: dpi);
    return dot;
  }

  // ######################
  // Private
  // ######################

  bool _isDisposed = false;
  bool _isErased = false;

  T? _mockedProduct;

  // ...........................................................................
  final List<Insert<T>> _inserts = [];

  // ...........................................................................
  NodeBluePrint<T> get _bluePrint => _bluePrints.last;

  final List<NodeBluePrint<T>> _bluePrints = [];

  // ...........................................................................
  Priority _ownPriority = Priority.frame;

  // ...........................................................................
  final List<Supplier<dynamic>> _suppliers = [];
  final List<Customer<dynamic>> _customers = [];

  // ...........................................................................
  void _addOrReplaceSupplier(Supplier<dynamic> supplier) {
    assert(supplier != this);

    // Supplier<T> already added? Do nothing.
    if (_suppliers.contains(supplier)) {
      return;
    }

    // Remove existing supplier
    final path = _supplierPath(supplier);
    final existingSupplier = _supplierForPath(path);
    if (existingSupplier != null) {
      _removeSupplier(existingSupplier); // coverage:ignore-line
    }

    // Add supplier to list of suppliers
    _suppliers.add(supplier);

    // This producer becomes a customer of its supplier
    supplier._addCustomer(this);

    // Because we have new dependencies, a rebuild is needed
    scm.nominate(this);
  }

  // ...........................................................................
  void _removeSupplier(Supplier<dynamic> supplier) {
    if (!_suppliers.contains(supplier)) {
      return;
    }

    _suppliers.remove(supplier);
    assert(supplier.customers.contains(this));
    supplier._removeCustomer(this);
  }

  // ...........................................................................
  void _addCustomer(Customer<dynamic> customer) {
    if (_customers.contains(customer)) {
      return;
    }

    _customers.add(customer);
    customer._addOrReplaceSupplier(this);
  }

  // ...........................................................................
  void _removeCustomer(Customer<dynamic> customer) {
    if (!_customers.contains(customer)) {
      return;
    }

    _customers.remove(customer);
    customer._removeSupplier(this);
    if (isDisposed && customers.isEmpty) {
      _erase();
    }
  }

  // ...........................................................................
  // Tick & Animation
  bool _isAnimated = false;

  // ...........................................................................
  bool _matchesPath(List<String> path) {
    path = [...path];
    final key = path.last;
    if (key != this.key) {
      return false;
    }

    path = path.sublist(0, path.length - 1);
    return scope.matchesPathArray(path);
  }

  // ...........................................................................
  void _throwIfNotAllowed(T product) {
    // Check, if the new product is allowed
    if (bluePrint.allowedProducts.isNotEmpty) {
      if (!bluePrint.allowedProducts.contains(product)) {
        throw ArgumentError(
          'The product $product '
          'is not in the list of allowed products '
          '[${bluePrint.allowedProducts.join(', ')}].',
        );
      }
    }
  }

  // ...........................................................................
  /// Moves the customers of this node to the target node
  void moveCustomersTo(Node<T> targetNode) {
    for (final customer in [...customers]) {
      // Move the customer to the smartNode

      targetNode._customers.add(customer);
      _customers.remove(customer);

      // Replace the old suppliers by the smartNode
      final supplierIndex = customer._suppliers.indexOf(this);

      customer._suppliers[supplierIndex] = targetNode;
      scm.nominate(customer);
    }

    if (isDisposed) {
      _erase();
    }
  }

  // ...........................................................................
  void _addBluePrint(NodeBluePrint<T> bluePrint) {
    final oldBluePrint = this.bluePrint;

    if (bluePrint == oldBluePrint) {
      return;
    }

    assert(bluePrint.key == this.bluePrint.key);

    // Update the bluePrint
    this._bluePrints.add(bluePrint);

    // Trigger a re-initialization of suppliers
    needsInitSuppliers();

    // If the produce function has changed, we need to produce again
    if (bluePrint.produce != oldBluePrint.produce) {
      scm.nominate(this);
    }
  }

  // ...........................................................................
  String _supplierPath(Node<dynamic> node) {
    final result = <String>[];

    for (final supplierPath in bluePrint.suppliers) {
      if (node.matchesPath(supplierPath)) {
        result.add(supplierPath);
      }
    }

    assert(result.length == 1);

    return result.first;
  }

  // ...........................................................................
  Node<dynamic>? _supplierForPath(String path) {
    for (final supplier in suppliers) {
      if (supplier.matchesPath(path)) {
        return supplier;
      }
    }
    return null;
  }

  // ...........................................................................
  void _clearSuppliers() {
    _suppliersAreInitialized = bluePrint.suppliers.isEmpty;

    for (final supplier in [...suppliers]) {
      _removeSupplier(supplier);
    }

    if (!_suppliersAreInitialized) {
      scm.needsInitSuppliers(this);
    }
  }

  // ...........................................................................
  void _detectCircularDependencies(
    Node<dynamic> node,
    Iterable<Node<dynamic>> suppliers,
    List<Node<dynamic>> visited,
  ) {
    if (suppliers.contains(node)) {
      visited.add(node);
      final path = visited.reversed.map((n) => n.key).join(' -> ');
      throw Exception('Circular dependency detected: $path');
    }

    for (final supplier in suppliers) {
      _detectCircularDependencies(node, supplier.suppliers, [
        ...visited,
        supplier,
      ]);
    }
  }
}

// ######################
// Examples
// ######################

/// Provides a deeply configured node sructure
class ButterFlyExample {
  /// Constructor
  ButterFlyExample({bool withScopes = false}) {
    final scope = Scope.example(scm: Scm.example(), key: 'butterFly');

    final s11Bp = nbp(from: ['s111'], to: 's11', init: 's11');
    final s1Bp = nbp(from: ['s11', 's10'], to: 's1', init: 's1');
    final s0Bp = nbp(from: ['s01', 's00'], to: 's0', init: 's0');
    final xBp = nbp(from: ['s1', 's0'], to: 'x', init: 'x');
    final c00Bp = nbp(from: ['c0'], to: 'c00', init: '0');
    final c01Bp = nbp(from: ['c0'], to: 'c01', init: '0');

    final c0Bp = nbp(from: ['x'], to: 'c0', init: '0');
    final c1Bp = nbp(from: ['x'], to: 'c1', init: '1');

    final c10Bp = nbp(from: ['c1'], to: 'c10', init: '0');
    final c11Bp = nbp(from: ['c1'], to: 'c11', init: '0');

    final c111Bp = nbp(from: ['c11'], to: 'c111', init: 'c111');

    if (withScopes) {
      scope.mockContent({
        'level3': {
          's111': 's111',
          'level2': {
            's11': s11Bp,
            's10': 's10',
            's01': 's01',
            's00': 's00',
            'level1': {
              's1': s1Bp,
              's0': s0Bp,
              'level0': {'x': xBp},
              'c0': c0Bp,
              'c1': c1Bp,
            },
            'c00': c00Bp,
            'c01': c01Bp,
            'c10': c10Bp,
            'c11': c11Bp,
          },
          'c111': c111Bp,
        },
      });
    } else {
      scope.mockContent({
        's111': 's111',
        's11': s11Bp,
        's10': 's10',
        's01': 's01',
        's00': 's00',
        's1': s1Bp,
        's0': s0Bp,
        'x': xBp,
        'c0': c0Bp,
        'c1': c1Bp,
        'c00': c00Bp,
        'c01': c01Bp,
        'c10': c10Bp,
        'c11': c11Bp,
        'c111': c111Bp,
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

    if (withScopes) {
      level0 = scope.findChildScope('level0')!;
      level1 = scope.findChildScope('level1')!;
      level2 = scope.findChildScope('level2')!;
      level3 = scope.findChildScope('level3')!;

      allScopes = [level0, level1, level2, level3, scope];
    } else {
      allScopes = [];
    }

    scope.scm.testFlushTasks();
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
        'left': nbp(from: ['top'], to: 'left', init: 0),
      },
      'right': {
        'right': nbp(from: ['top', 'left'], to: 'right', init: 0),
      },
    });

    topNode = triangle.findNode<int>('top')!;
    leftNode = triangle.findNode<int>('left')!;
    rightNode = triangle.findNode<int>('right')!;

    topScope = triangle;
    leftScope = triangle.findChildScope('left')!;
    rightScope = triangle.findChildScope('right')!;

    allNodes = [topNode, leftNode, rightNode];
    allScopes = [topScope, leftScope, rightScope];

    triangle.scm.testFlushTasks();
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
