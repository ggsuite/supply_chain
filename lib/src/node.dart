// @license
// Copyright (c) 2019 - 2023 ggsuite. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:async' show FutureOr;

import 'package:meta/meta.dart';
import 'package:supply_chain/supply_chain.dart';

/// A supplier delivers products to a node
typedef Supplier<T> = Node<T>;

/// A customer receives products to a node
typedef Customer<T> = Node<T>;

/// A worker is a node on the assembly line
typedef Worker<T> = Node<T>;

/// Produce delegate
///
/// May return a product synchronously ([T]) or asynchronously ([Future<T>]).
/// Synchronous producers behave exactly as before. Asynchronous producers
/// keep the node in production until their [Future] resolves or the node's
/// [Node.productionTimeout] elapses.
typedef Produce<T> =
    FutureOr<T> Function(
      List<dynamic> components,
      T previousProduct,
      Node<T> node,
    );

/// A node in a scope
class Node<T> {
  // ...........................................................................
  /// - [bluePrint]: The blue print configuring this node, including its
  ///   produce function, key and initial product
  /// - [scope]: The scope the node belongs to
  /// - [isInsert]: Whether this node is an insert in a host node's chain
  /// - [owner]: The optional owner notified about lifecycle events
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

  /// Allows to listen to 'on/change'
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

    // Remove the node from the scm's prepared sets. Disposed nodes must not
    // keep the production pipeline open.
    scm.removeDisposedNode(this);

    // Supersede any in-flight asynchronous production so its late result is
    // discarded by [_onAsyncResult].
    _produceGeneration++;
    _isProducingAsync = false;

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
    scope.removeNode(key);
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
  String get path => '${scope.path}/$key';

  /// Returns true, if this path matches the given path
  bool matchesPath(String path) => _matchesPath(path.split('/'));

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

  /// Returns the product converted to a JSON value
  dynamic get productAsJson => bluePrint.toJson(product);

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

  /// Sets the product from a JSON value
  set productAsJson(dynamic json) {
    product = bluePrint.fromJson(json);
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
    isStaged = true;
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

  /// Whether this node has finished at least one production. Used by the
  /// change-gating in [_applyProduct]: the first production always propagates.
  bool _producedAtLeastOnce = false;

  /// Monotonic production generation.
  ///
  /// Incremented on every [produce] call. An asynchronous production captures
  /// the generation it started with; when its future resolves with a different
  /// current generation (e.g. because the node was re-nominated, mocked or
  /// disposed in the meantime) the result is discarded as superseded.
  int _produceGeneration = 0;

  bool _isProducingAsync = false;

  /// Returns true while an asynchronous production is in flight.
  bool get isProducingAsync => _isProducingAsync;

  /// Produces the product.
  ///
  /// The produce function may return its product synchronously ([T]) or
  /// asynchronously ([Future<T>]). Synchronous products are applied
  /// immediately (unchanged behavior). Asynchronous products keep the node in
  /// production until the future resolves or the node's [productionTimeout]
  /// elapses (see [Scm]).
  void produce({bool announce = true, bool triggerOnChange = true}) {
    assert(!isDisposed);
    assert(_suppliersAreInitialized);

    // Each production gets a unique generation. This supersedes any in-flight
    // asynchronous production from a previous call (including the mocked case
    // below), so its late result will be discarded by [_onAsyncResult].
    final generation = ++_produceGeneration;

    if (_mockedProduct != null) {
      _isProducingAsync = false;
      scm.unregisterAsyncProduction(this);
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

    final result = bluePrint.produce(_products, previousProduct, this);

    // Asynchronous production: keep the node in production. The result is
    // applied when the future resolves (see [_onAsyncResult]). Until then the
    // node stays in scm.producingNodes - or until its productionTimeout
    // elapses, in which case it is finalized with the previous product.
    if (result is Future<T>) {
      _isProducingAsync = true;
      scm.registerAsyncProduction(this, result);
      result.then(
        (value) => _onAsyncResult(value, generation, announce, triggerOnChange),
        onError: (Object error, StackTrace stack) =>
            _onAsyncError(error, stack, generation, announce, triggerOnChange),
      );
      return;
    }

    // Synchronous production.
    _applyProduct(result, announce, triggerOnChange);
  }

  // ...........................................................................
  /// Applies a freshly produced [newProduct] and announces it via the SCM.
  void _applyProduct(T newProduct, bool announce, bool triggerOnChange) {
    _throwIfNotAllowed(newProduct);

    final previous = _originalProduct;
    _originalProduct = newProduct;

    // Change-gating: a node configured with propagateOnChangeOnly does not
    // schedule its customers when the freshly produced product equals the
    // previous one. The first production and insert chains always propagate.
    final gate =
        bluePrint.propagateOnChangeOnly &&
        _producedAtLeastOnce &&
        !isInsert &&
        _inserts.isEmpty &&
        _productIsUnchanged(previous, newProduct);
    _producedAtLeastOnce = true;

    // If this node is the last insert in the chain,
    // write the product into the host's insertResult
    if (isInsert) {
      final insert = this as Insert<T>;
      if (insert.isLastInsert) {
        insert.host.insertResult = newProduct;
      }
    }

    // Announce
    if (announce) {
      if (gate) {
        scm.finalizeWithoutPropagation(this);
      } else {
        scm.hasNewProduct(this);
      }
    }

    if (triggerOnChange && !gate) {
      _triggerOnChange();
    }
  }

  // ...........................................................................
  /// Returns true if [next] equals [previous] according to the blue print's
  /// [NodeBluePrint.changeComparator] (or `==` when none is configured).
  bool _productIsUnchanged(T previous, T next) =>
      bluePrint.changeComparator?.call(previous, next) ?? (previous == next);

  // ...........................................................................
  /// Handles the result of an asynchronous production.
  void _onAsyncResult(
    T value,
    int generation,
    bool announce,
    bool triggerOnChange,
  ) {
    // Superseded by a newer production, or the node is gone: discard. Do not
    // touch the registry here - a newer production may own the current entry.
    if (generation != _produceGeneration || isDisposed || isErased) {
      return;
    }

    _isProducingAsync = false;
    scm.unregisterAsyncProduction(this);

    // Resolved within the production timeout and still producing: announce the
    // new product through the regular path (single update).
    if (scm.producingNodes.contains(this)) {
      _applyProduct(value, announce, triggerOnChange);
      return;
    }

    // The production timeout already finalized this node with the previous
    // product. Apply the fresh product now and propagate it as a follow-up
    // update. We must not call scm.hasNewProduct here because the node already
    // left scm.producingNodes.
    _throwIfNotAllowed(value);
    _originalProduct = value;
    if (isInsert) {
      final insert = this as Insert<T>;
      if (insert.isLastInsert) {
        insert.host.insertResult = value;
      }
    }
    if (triggerOnChange) {
      _triggerOnChange();
    }
    scm.applyLateAsyncResult(this);
  }

  // ...........................................................................
  /// Handles a rejected asynchronous production.
  void _onAsyncError(
    Object error,
    StackTrace stack,
    int generation,
    bool announce,
    bool triggerOnChange,
  ) {
    if (generation != _produceGeneration || isDisposed || isErased) {
      return;
    }

    _isProducingAsync = false;
    scm.unregisterAsyncProduction(this);

    // Keep the previous product. Surface the error through the SCM hook.
    scm.reportProductionError(this, error, stack);

    // Free the node from production. If the timeout already finalized it, the
    // previous product is already in place and there is nothing to propagate.
    if (scm.producingNodes.contains(this)) {
      scm.hasNewProduct(this);
    }
  }

  /// Returns true, if node is staged for production
  bool isStaged = false;

  /// Finalizes production
  void finalizeProduction() {
    isStaged = false;
  }

  // ...........................................................................
  // Suppliers

  /// The suppliers of the node
  Iterable<Node<dynamic>> get suppliers => _suppliers;

  /// Get suppliers of the node of a given depth
  ///
  /// With a negative [depth] ALL transitive suppliers are returned, each
  /// exactly once. With a bounded depth, nodes reachable via multiple paths
  /// are contained once per path.
  Iterable<Node<dynamic>> deepSuppliers({int depth = 1}) {
    // Unlimited depth: traverse each node once. Without the visited set the
    // enumeration would be exponential on diamond shaped graphs.
    if (depth < 0) {
      return _collectDeep(this, (n) => n._suppliers);
    }

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
  /// Collects all nodes transitively reachable from [root] via [edges],
  /// each exactly once, in depth first pre-order (direct neighbors first,
  /// then the neighbors of the first neighbor, etc.).
  ///
  /// Iterative: the recursion depth would equal the graph depth and
  /// overflow the stack on deep chains.
  static List<Node<dynamic>> _collectDeep(
    Node<dynamic> root,
    Iterable<Node<dynamic>> Function(Node<dynamic>) edges,
  ) {
    final result = <Node<dynamic>>[];
    final visited = <Node<dynamic>>{root};
    final stack = <Node<dynamic>>[root];

    while (stack.isNotEmpty) {
      final node = stack.removeLast();

      // Emit all yet unvisited neighbors first
      final next = <Node<dynamic>>[];
      for (final neighbor in edges(node)) {
        if (visited.add(neighbor)) {
          result.add(neighbor);
          next.add(neighbor);
        }
      }

      // Then descend into them, starting with the first one
      for (final neighbor in next.reversed) {
        stack.add(neighbor);
      }
    }

    return result;
  }

  /// Call this method to update the suppliers again
  void needsInitSuppliers() {
    _clearSuppliers();
  }

  /// Is called by SCM to initialize the suppliers
  void initSuppliers(Map<String, Node<dynamic>> newSuppliers) {
    _throwOnCircularDependencies(newSuppliers);

    // Make sure the keys match the blue print's suppliers
    final s = bluePrint.suppliers;
    for (var supplierKey in newSuppliers.keys) {
      assert(s.contains(supplierKey) || s.contains('../$supplierKey'));
    }

    // Reset old suppliers
    for (final supplier in [...suppliers]) {
      _removeSupplier(supplier); // coverage:ignore-line
    }

    // Add the new suppliers. All old suppliers were removed before, so each
    // supplier is guaranteed to be new and no replacement lookup is needed.
    for (final supplier in newSuppliers.values) {
      _addNewSupplier(supplier);
    }

    // Enlarge or shrink _products
    _products.length = suppliers.length;

    _suppliersAreInitialized = true;
  }

  // ...........................................................................
  // Customers

  /// The customers of the node
  Iterable<Node<dynamic>> get customers => _customers;

  /// Get customers of the node of a given depth
  ///
  /// With a negative [depth] ALL transitive customers are returned, each
  /// exactly once. With a bounded depth, nodes reachable via multiple paths
  /// are contained once per path.
  Iterable<Node<dynamic>> deepCustomers({int depth = 1}) {
    // Unlimited depth: traverse each node once. Without the visited set the
    // enumeration would be exponential on diamond shaped graphs.
    if (depth < 0) {
      return _collectDeep(this, (n) => n._customers);
    }

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
    final masterPath = smartMaster;
    Scope? parent = scope;
    while (parent != null) {
      final foundMaster = parent.findDirectChildNode<T>(masterPath);
      if (foundMaster != null &&
          !foundMaster.isDisposed &&
          foundMaster != this &&
          foundMaster.scope != scope) {
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

  /// The production timeout for this node.
  ///
  /// Uses the node's blue print [NodeBluePrint.productionTimeout] when set,
  /// otherwise falls back to the SCM's global [Scm.timeout].
  Duration get productionTimeout => bluePrint.productionTimeout ?? scm.timeout;

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
    if (isMetaNode) {
      return const [];
    }

    final result = <Node<dynamic>>[];

    // Add the onChange node of the own scope
    if (onChangeEnabled) {
      result.add(scope.onChange!);
    }

    // Add onChangeRecursive of this node and it's parents
    if (onRecursiveChangeEnabled) {
      Scope? parent = scope;
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
    _topoRank = scm.nextTopoRank();
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
  /// Save the graph to a file
  ///
  /// The format can be dot, mmd, md, svg, png, pdf
  Future<void> writeImageFile(
    String path, {
    int supplierDepth = 0,
    int customerDepth = 0,
    List<Node<dynamic>>? highlightedNodes,
    List<Scope>? highlightedScopes,
    double scale = 1.0,
    bool write2x = false,
    MarkdownFormat markdownFormat = MarkdownFormat.gitHub,
  }) async {
    final g = graph(
      supplierDepth: supplierDepth,
      customerDepth: customerDepth,
      highlightedNodes: highlightedNodes ?? [this],
      highlightedScopes: highlightedScopes,
    );

    await Graph.writeImageFile(
      path: path,
      graph: g,
      scale: scale,
      write2x: write2x,
      markdownFormat: markdownFormat,
    );
  }

  // ...........................................................................
  /// Returns an graph
  GraphScopeItem graph({
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
      highlightedNodes: highlightedNodes ?? [this], // coverage:ignore-line
      highlightedScopes: highlightedScopes,
    );
    return tree;
  }

  // ...........................................................................
  /// Returns a dot graph that can be turned into svg using graphviz
  String dot({
    int supplierDepth = 0,
    int customerDepth = 0,
    List<Node<dynamic>>? highlightedNodes,
    List<Scope>? highlightedScopes,
  }) {
    final g = graph(
      supplierDepth: supplierDepth,
      customerDepth: customerDepth,
      highlightedNodes: highlightedNodes ?? [this],
      highlightedScopes: highlightedScopes,
    );

    final dot = GraphToDot(graph: g).dot;
    return dot;
  }

  // ...........................................................................
  /// Returns a mermaid graph
  String mermaid({
    int supplierDepth = 0,
    int customerDepth = 0,
    List<Node<dynamic>>? highlightedNodes,
    List<Scope>? highlightedScopes,
  }) {
    final g = graph(
      supplierDepth: supplierDepth,
      customerDepth: customerDepth,
      highlightedNodes: highlightedNodes ?? [this],
      highlightedScopes: highlightedScopes,
    );

    final mm = GraphToMermaid(graph: g).mermaid;
    return mm;
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
  // _suppliers is a List because the order of the suppliers must match the
  // order of the blue print's supplier paths (it defines the order of the
  // components handed to produce). _suppliersSet shadows the list for O(1)
  // contains checks.
  final List<Supplier<dynamic>> _suppliers = [];
  final Set<Supplier<dynamic>> _suppliersSet = {};
  final Set<Customer<dynamic>> _customers = {};

  // ...........................................................................
  /// The node's position in a topological order of the supplier graph:
  /// suppliers have smaller ranks than their customers.
  ///
  /// Maintained incrementally (Pearce-Kelly): most edges connect a lower
  /// rank to a higher rank and cost O(1) to check for cycles. Only edges
  /// violating the current order trigger a search of the affected region
  /// plus a local rank reordering.
  late int _topoRank;

  // ...........................................................................
  /// Adds a supplier that is guaranteed not to be one of the current
  /// suppliers, e.g. because all suppliers were removed before.
  void _addNewSupplier(Supplier<dynamic> supplier) {
    assert(supplier != this);

    // Supplier<T> already added? Do nothing.
    if (_suppliersSet.contains(supplier)) {
      return;
    }

    // Keep the topological ranks in order
    _restoreTopoOrderForEdge(supplier, this);

    // Add supplier to list of suppliers
    _suppliers.add(supplier);
    _suppliersSet.add(supplier);

    // This producer becomes a customer of its supplier
    supplier._addCustomer(this);

    // Because we have new dependencies, a rebuild is needed
    scm.nominate(this);
  }

  // ...........................................................................
  void _removeSupplier(Supplier<dynamic> supplier) {
    if (!_suppliersSet.contains(supplier)) {
      return;
    }

    _suppliers.remove(supplier);
    _suppliersSet.remove(supplier);
    assert(supplier.customers.contains(this));
    supplier._removeCustomer(this);
  }

  // ...........................................................................
  /// Is called by [_addNewSupplier] after this node was added to the
  /// customer's supplier list.
  void _addCustomer(Customer<dynamic> customer) {
    _customers.add(customer);
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

      _restoreTopoOrderForEdge(targetNode, customer);
      customer._suppliers[supplierIndex] = targetNode;
      customer._suppliersSet.remove(this);
      customer._suppliersSet.add(targetNode);
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
    _bluePrints.add(bluePrint);

    // Trigger a re-initialization of suppliers
    needsInitSuppliers();

    // If the produce function has changed, we need to produce again
    if (bluePrint.produce != oldBluePrint.produce) {
      scm.nominate(this);
    }
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
  /// Throws if connecting this node to [newSuppliers] would create a cycle.
  ///
  /// Thanks to the topological ranks this is O(1) per supplier for the
  /// common case (supplier rank < customer rank). Only suppliers violating
  /// the current order require a reachability check, bounded to the affected
  /// rank region. Throws before any supplier is connected.
  void _throwOnCircularDependencies(Map<String, Node<dynamic>> newSuppliers) {
    for (final supplier in newSuppliers.values) {
      // A supplier with a smaller rank can never close a cycle.
      if (supplier._topoRank < _topoRank) {
        continue;
      }

      // The supplier is the node itself or reachable from the node via
      // customer edges? Then the new edge would close a cycle.
      if (identical(supplier, this) ||
          _isReachableViaCustomers(from: this, target: supplier)) {
        _throwCircularDependency(this, newSuppliers.values, [this]);
      }
    }
  }

  // ...........................................................................
  /// Returns true if [target] is reachable from [from] via customer edges.
  ///
  /// The search is bounded to the rank region `<= target._topoRank`: in a
  /// valid topological order every path towards [target] has strictly
  /// increasing ranks.
  static bool _isReachableViaCustomers({
    required Node<dynamic> from,
    required Node<dynamic> target,
  }) {
    final maxRank = target._topoRank;
    final visited = <Node<dynamic>>{};
    final stack = <Node<dynamic>>[from];

    while (stack.isNotEmpty) {
      final current = stack.removeLast();
      if (identical(current, target)) {
        return true;
      }
      if (current._topoRank > maxRank || !visited.add(current)) {
        continue;
      }
      stack.addAll(current._customers);
    }
    return false;
  }

  // ...........................................................................
  /// Restores the topological order before adding the edge
  /// [supplier] -> [customer] (Pearce-Kelly).
  ///
  /// When the edge already respects the order (supplier rank < customer
  /// rank) this is O(1). Otherwise the affected rank region is searched and
  /// locally reordered. If the new edge closes a cycle no order exists; the
  /// ranks are left untouched (callers detect and report cycles themselves,
  /// see [_throwOnCircularDependencies]).
  static void _restoreTopoOrderForEdge(
    Node<dynamic> supplier,
    Node<dynamic> customer,
  ) {
    if (supplier._topoRank < customer._topoRank) {
      return;
    }

    // Collect all nodes reachable forward from the customer within the
    // affected region (they must move behind the supplier).
    final maxRank = supplier._topoRank;
    final forward = <Node<dynamic>>{};
    var stack = <Node<dynamic>>[customer];
    while (stack.isNotEmpty) {
      final current = stack.removeLast();
      if (identical(current, supplier)) {
        // The new edge closes a cycle - no topological order exists.
        return;
      }
      if (current._topoRank > maxRank || !forward.add(current)) {
        continue;
      }
      stack.addAll(current._customers);
    }

    // Collect all nodes reaching the supplier backwards within the affected
    // region (they must move before the customer's region).
    final minRank = customer._topoRank;
    final backward = <Node<dynamic>>{};
    stack = <Node<dynamic>>[supplier];
    while (stack.isNotEmpty) {
      final current = stack.removeLast();
      if (current._topoRank < minRank || !backward.add(current)) {
        continue;
      }
      stack.addAll(current._suppliers);
    }

    // Reassign the affected ranks: backward nodes keep their relative order
    // and move before the forward nodes, which also keep theirs.
    final pool = [
      for (final node in backward) node._topoRank,
      for (final node in forward) node._topoRank,
    ]..sort();

    final backwardSorted = [...backward]
      ..sort((a, b) => a._topoRank - b._topoRank);
    final forwardSorted = [...forward]
      ..sort((a, b) => a._topoRank - b._topoRank);

    var i = 0;
    for (final node in backwardSorted) {
      node._topoRank = pool[i++];
    }
    for (final node in forwardSorted) {
      node._topoRank = pool[i++];
    }
  }

  // ...........................................................................
  /// Reconstructs the cycle path and throws. Only called on the error path.
  void _throwCircularDependency(
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
      _throwCircularDependency(node, supplier.suppliers, [
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

    scope.scm.flush();
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

    triangle.scm.flush();
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
