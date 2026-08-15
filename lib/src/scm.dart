// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:async' show scheduleMicrotask, Timer, Zone;

import 'package:gg_fake_stopwatch/gg_fake_stopwatch.dart';
import 'package:gg_fake_timer/gg_fake_timer.dart';
import 'package:gg_once_per_cycle/gg_once_per_cycle.dart';
import 'package:supply_chain/supply_chain.dart';

import 'schedule_task.dart';

/// SCM - Supply Chain Manager: Controls the data flow in the supply chain.
class Scm {
  // ######################
  // Public
  // ######################

  // ...........................................................................
  /// Supply chain manager constructor
  Scm({this.isTest = false}) {
    _init();
  }

  // ...........................................................................
  /// Default supply chain manager
  static final Scm testInstance = Scm(isTest: true);

  // ...........................................................................
  /// The root supply chain
  late final Scope rootScope;

  // ...........................................................................
  /// Initializes suppliers
  void initSuppliers() => _initSuppliers();

  // ...........................................................................
  /// Returns iterable of all nodes
  Iterable<Node<dynamic>> get nodes => _nodes;

  /// Returns all nodes having a given key
  Iterable<Node<T>> nodesWithKey<T>(String key) {
    final nodes = _nodesByKey[key];
    if (nodes == null) {
      return const [];
    }
    return nodes.whereType<Node<T>>();
  }

  /// Returns true if at least one node with the given key exists.
  ///
  /// Used by [Scope.findNode] to fail fast: when no node with the searched
  /// key exists at all, the expensive search through the scope tree can be
  /// skipped.
  bool hasNodesWithKey(String key) => _nodesByKey.containsKey(key);

  /// Adds a node to scm
  void addNode(Node<dynamic> node) {
    _assertNodeIsNotErased(node);
    _nodes.add(node);
    (_nodesByKey[node.key] ??= {}).add(node);

    nominate(node);
  }

  /// Removes the node from scm
  void removeNode(Node<dynamic> node) {
    _nodes.remove(node);

    final nodesWithSameKey = _nodesByKey[node.key];
    if (nodesWithSameKey != null) {
      nodesWithSameKey.remove(node);
      if (nodesWithSameKey.isEmpty) {
        _nodesByKey.remove(node.key);
      }
    }

    _animatedNodes.remove(node);
    _nominatedNodes.remove(node);
    _removePreparedNode(node);
    _producingNodes.remove(node);
    _removeSmartNode(node);
    _nodesWithMissedSuppliers.remove(node);
    _nodesNeedingSupplierUpdate.remove(node);
    _asyncProductions.remove(node);
    _nodesWithChangedPriority.remove(node);
    _readyQueuesNeedRevalidation = true;
  }

  /// Called by [Node.dispose]: removes the node from the prepared sets so
  /// that disposed nodes do not keep the production pipeline open.
  void removeDisposedNode(Node<dynamic> node) {
    _removePreparedNode(node);
    _readyQueuesNeedRevalidation = true;
  }

  /// Adds node for initialization of suppliers
  void needsInitSuppliers(Node<dynamic> node) {
    _nodesNeedingSupplierUpdate.add(node);
    _readyQueuesNeedRevalidation = true;
  }

  /// Nominate node for production
  void nominate(Node<dynamic> node) {
    // If the node has no customers, it is more efficient to produce it
    // directly. Check the cheap O(1) conditions first; isReadyToProduce
    // scans the suppliers and is evaluated last.
    if (node.suppliers.isEmpty &&
        node.customers.isEmpty &&
        node.inserts.isEmpty &&
        node.isInitialized &&
        !node.isInsert &&
        !node.isDisposed &&
        node.isReadyToProduce) {
      node.produce(announce: false, triggerOnChange: true);

      // For asynchronous productions the node finalizes itself once its future
      // resolves (see Node._onAsyncResult). Only finalize synchronous ones.
      if (!node.isProducingAsync) {
        node.finalizeProduction();
      }
      return;
    }

    _assertNodeIsNotErased(node);
    _nominatedNodes.add(node);
    _schedulePreparation.trigger();
  }

  /// Inform scm about an update
  ///
  /// With [propagate] set to false the node leaves the production pipeline
  /// cleanly, but its customers and inserts are not scheduled. Used by nodes
  /// configured with [NodeBluePrint.propagateOnChangeOnly] when a freshly
  /// produced product equals the previously propagated one.
  void hasNewProduct(
    Node<dynamic> node, {
    bool? extraChecks,
    bool propagate = true,
  }) {
    // Node is not in producing nodes?
    // Throw an exception. Only producing nodes should call hasNewProduct()
    final check = extraChecks ?? Scm.extraChecks;
    if (check && !_producingNodes.contains(node)) {
      throw StateError(
        'Node "$node" did call "hasNewProduct()" '
        'without being nominated before.',
      );
    }

    // Finalize production
    _finalizeProduction(node, propagate: propagate);
  }

  // ...........................................................................
  // Asynchronous production

  /// The futures of all currently in-flight asynchronous productions.
  Iterable<Future<dynamic>> get pendingAsyncProductions =>
      _asyncProductions.values;

  /// Registers an in-flight asynchronous production. Called by [Node.produce].
  void registerAsyncProduction(Node<dynamic> node, Future<dynamic> future) {
    _asyncProductions[node] = future;
  }

  /// Unregisters an in-flight asynchronous production.
  void unregisterAsyncProduction(Node<dynamic> node) {
    _asyncProductions.remove(node);
  }

  /// Applies an asynchronous result that resolved after the node had already
  /// been finalized with its previous product (its [Node.productionTimeout]
  /// elapsed). Schedules the node's customers and inserts so the fresh product
  /// propagates as a follow-up update.
  void applyLateAsyncResult(Node<dynamic> node) {
    // The caller ([Node._onAsyncResult]) already guarded against disposed or
    // superseded nodes. Re-enter and immediately finalize so customers /
    // inserts are scheduled through the regular path.
    _producingNodes.add(node);
    _finalizeProduction(node);
  }

  /// Optional hook invoked when an asynchronous production future rejects.
  ///
  /// When set, the hook receives the failing node, the error and the stack
  /// trace. The node keeps its previous product. When `null`, the error is
  /// forwarded to the current [Zone] (so it surfaces during tests) without
  /// crashing the supply chain.
  void Function(Node<dynamic> node, Object error, StackTrace stack)?
  onProductionError;

  /// Reports an asynchronous production error. Called by [Node].
  void reportProductionError(
    Node<dynamic> node,
    Object error,
    StackTrace stack,
  ) {
    final handler = onProductionError;
    if (handler != null) {
      handler(node, error, stack);
    } else {
      Zone.current.handleUncaughtError(error, stack);
    }
  }

  // ...........................................................................
  // Animation

  /// Returns currently animated nodes
  Iterable<Node<dynamic>> get animatedNodes => _animatedNodes;

  /// Starts to animate node
  void animateNode(Node<dynamic> node) => _animatedNodes.add(node);

  /// Stops to animate node
  void deanimateNode(Node<dynamic> node) => _animatedNodes.remove(node);

  /// Call this method to trigger animation frame calculation
  void tick() => _tick();

  /// Monotonic counter of the ticks that nominated the animated nodes.
  ///
  /// [AnimatedNode] compares it against the value seen at its previous
  /// production to decide whether a production is tick-driven (advance one
  /// frame) or was triggered by a supplier re-emission between ticks (do
  /// not consume a frame).
  int get tickCount => _tickCount;

  // ...........................................................................
  // Product live cycle

  /// List of nodes, nominated for production
  Iterable<Node<dynamic>> get nominatedNodes => _nominatedNodes;

  /// List of nodes, prepared for production
  Iterable<Node<dynamic>> get preparedNodes => _preparedNodes;

  /// List of nodes, currently in production
  Iterable<Node<dynamic>> get producingNodes => _producingNodes;

  // ...........................................................................
  // Priority

  /// Inform the scm that a node's priority has changed
  void priorityHasChanged(Node<dynamic> node) {
    _nodesWithChangedPriority.add(node);
    _readyQueuesNeedRevalidation = true;
    _schedulePriorityUpdate.trigger();
  }

  /// Nodes with a priority below this priority are not processed
  Priority get minProductionPriority => _minProductionPriority;

  // ...........................................................................
  /// Cleanup
  void clear() {
    _nominatedNodes.clear();
    _preparedNodes.clear();
    _preparedInsertNodes.clear();
    _producingNodes.clear();
    _asyncProductions.clear();

    for (final queue in _readyNodes) {
      queue.clear();
    }
    for (final queue in _readyInsertNodes) {
      queue.clear();
    }
  }

  // ...........................................................................
  // Timeouts

  /// Set this property to true, if production timeouts should block
  ///
  /// Note for asynchronous producers: while a node is producing, [tick] does
  /// not start new frames. The production timeout is what frees a stuck async
  /// node (by finalizing it with the previous product). When [shouldTimeOut]
  /// is `false`, an asynchronous production whose future never completes will
  /// therefore block the frame pipeline indefinitely. With timeouts disabled,
  /// only use asynchronous producers whose futures are guaranteed to complete.
  bool shouldTimeOut = true;

  // ...........................................................................
  /// Opt-in: process all production waves within a single scheduled cycle.
  ///
  /// By default the scm processes exactly one readiness wave (one priority
  /// batch) per event-loop cycle. This keeps intermediate states observable
  /// but pays one microtask hop per wave - noticeable on deep chains.
  ///
  /// With [drainMode] enabled, production keeps processing waves until no
  /// more nodes become ready (or an asynchronous producer is in flight).
  /// Deep chains then propagate within a single cycle.
  ///
  /// Trade-offs: intermediate one-wave-per-cycle states are no longer
  /// observable between event-loop cycles, and all synchronous waves of an
  /// update share one cycle - production timeouts still apply per node.
  bool drainMode = false;

  // ...........................................................................
  /// Manages disposed nodes and scopes
  late final Disposed disposedItems;

  // ...........................................................................
  // SmartNodes

  /// Update smartNodes
  void updateSmartNodes(Node<dynamic> node) => _updateSmartNodes(node);

  // ######################
  // Testing
  // ######################

  /// Is used for testing
  bool isTest;

  /// Disable additional checks
  ///
  /// Performance note: with [extraChecks] enabled every announced
  /// production pays an extra containment check (see [hasNewProduct]).
  /// Set this to false in release builds of performance critical
  /// applications. Also consider compiling with `dart compile exe` (AOT):
  /// asserts are disabled there, removing all assert-only overhead.
  static bool extraChecks = true;

  // ...........................................................................
  // Test schedule tasts

  /// Runs scheduled normal tasks
  void testRunNormalTasks() => _testRunNormalTasks();

  /// Runs scheduled fast tasks
  void testRunFastTasks() => _testRunFastTasks();

  /// Returns currently scheduled fast tasks
  Iterable<Task> get testFastTasks => _testFastTasks;

  /// Returns currently scheduled normal tasks
  Iterable<Task> get testNormalTasks => _testNormalTasks;

  ///  Runs alls tasks until they are done
  void flush({bool tick = true}) {
    if (tick) {
      _tick();
    }

    while (_testFastTasks.isNotEmpty ||
        _testNormalTasks.isNotEmpty ||
        _nodesNeedingSupplierUpdate.isNotEmpty) {
      if (_nodesNeedingSupplierUpdate.isNotEmpty) {
        initSuppliers();
      }

      testRunNormalTasks();
      testRunFastTasks();

      if (tick && !_preparedNodesAreEmpty) {
        _tick();
      }
    }

    _initMissedSuppliers();
  }

  // ...........................................................................
  /// Like [flush], but also awaits in-flight asynchronous productions until
  /// the supply chain is quiescent.
  ///
  /// Use this in tests with asynchronous producers. Synchronous-only chains
  /// can keep using [flush]. Asynchronous `then` callbacks resolve on the real
  /// microtask queue, which [flush] cannot observe - hence this awaitable
  /// variant.
  Future<void> settle({bool tick = true}) async {
    var guard = 0;
    while (true) {
      // Pump all synchronous test tasks and supplier init.
      flush(tick: tick);

      final quiescent =
          _asyncProductions.isEmpty &&
          _testFastTasks.isEmpty &&
          _testNormalTasks.isEmpty &&
          _nodesNeedingSupplierUpdate.isEmpty &&
          _preparedNodesAreEmpty &&
          _producingNodes.isEmpty;
      if (quiescent) {
        break;
      }

      // Await all currently pending async productions. Their `then` callbacks
      // (which may re-nominate nodes) run afterwards; the loop re-checks.
      if (_asyncProductions.isNotEmpty) {
        await Future.wait(_asyncProductions.values.toList())
            .catchError((Object _) => <dynamic>[]); // per-node error handled
      }

      // Give microtask callbacks a chance to run before re-checking.
      await Future<void>.delayed(Duration.zero);

      // coverage:ignore-start
      if (++guard > 10000) {
        throw StateError(
          'settle() did not converge - possible circular async re-nomination.',
        );
      }
      // coverage:ignore-end
    }
  }

  /// Alias for [settle].
  Future<void> flushAsync({bool tick = true}) => settle(tick: tick);

  /// Clears all scheduled tasks
  void testClearScheduledTasks() {
    _testNormalTasks.clear();
    _testFastTasks.clear();
  }

  // ...........................................................................
  // Test timers

  /// Returns a test timer
  GgFakeTimer? get testTimer => _testTimer;

  /// Returns a test stop watch
  GgFakeStopwatch get testStopwatch => _testStopwatch;

  Stopwatch _testCreateStopWatch() {
    _testStopwatch = GgFakeStopwatch();
    return _testStopwatch;
  }

  /// Example supply chain manager for test purposes
  factory Scm.example({bool isTest = true}) => Scm(isTest: isTest);

  // ######################
  // Private
  // ######################

  // ...........................................................................
  void _init() {
    _initStopWatch();
    _initDisposed();
    _initSchedulePreparation();
    _initScheduleProduction();
    _initSchedulePriorityUpdate();
    _initRootScope();
  }

  // ...........................................................................
  void Function(Task) get _scheduleFast =>
      isTest ? _testScheduleFast : scheduleMicrotask;

  void Function(Task) get _scheduleNormal =>
      isTest ? _testScheduleNormal : Future.microtask;

  // ...........................................................................
  /// Hands out monotonically increasing topological ranks for new nodes.
  ///
  /// Nodes keep their rank a valid topological order of the supplier graph
  /// (suppliers before customers). This makes cycle detection cheap: adding
  /// an edge from a lower to a higher rank can never close a cycle.
  int nextTopoRank() => _nextTopoRank++;
  int _nextTopoRank = 0;

  // ...........................................................................
  // Nodes
  final Set<Node<dynamic>> _nodes = {};
  final Map<String, Set<Node<dynamic>>> _nodesByKey = {};
  final Set<Node<dynamic>> _animatedNodes = {};

  /// See [tickCount]
  int _tickCount = 0;

  // ...........................................................................
  final Set<Node<dynamic>> _nodesNeedingSupplierUpdate = {};
  final Set<Node<dynamic>> _nodesWithMissedSuppliers = {};

  // ...........................................................................
  // Smart nodes, additionally indexed by the last segment of their smart
  // master path. When a new node is created only the smart nodes whose
  // master path ends with the node's key can connect to it - so only they
  // need to be evaluated (see _connectNewMasterNodeToPotentialSmartNodes).
  final Set<Node<dynamic>> _smartNodes = {};
  final Map<String, Set<Node<dynamic>>> _smartNodesByMasterKey = {};
  final Map<Node<dynamic>, String> _smartNodeMasterKeys = {};

  // ...........................................................................
  void _addSmartNode(Node<dynamic> node) {
    final masterKey = node.smartMaster.last;
    final previousMasterKey = _smartNodeMasterKeys[node];

    // Already registered under the same master key? Do nothing.
    if (previousMasterKey == masterKey) {
      return;
    }

    // The smart master path may have changed - remove the old registration
    if (previousMasterKey != null) {
      _removeSmartNode(node); // coverage:ignore-line
    }

    _smartNodes.add(node);
    _smartNodeMasterKeys[node] = masterKey;
    (_smartNodesByMasterKey[masterKey] ??= {}).add(node);
  }

  // ...........................................................................
  void _removeSmartNode(Node<dynamic> node) {
    final masterKey = _smartNodeMasterKeys.remove(node);
    if (masterKey == null) {
      return;
    }

    _smartNodes.remove(node);

    final nodesWithMasterKey = _smartNodesByMasterKey[masterKey];
    if (nodesWithMasterKey != null) {
      nodesWithMasterKey.remove(node);
      if (nodesWithMasterKey.isEmpty) {
        _smartNodesByMasterKey.remove(masterKey);
      }
    }
  }

  // ...........................................................................
  // Processing stages
  final Set<Node<dynamic>> _nominatedNodes = {};
  final Set<Node<dynamic>> _preparedNodes = {};
  final Set<Node<dynamic>> _preparedInsertNodes = {};
  final Set<Node<dynamic>> _preparedRealtimeNodes = {};
  final Set<Node<dynamic>> _producingNodes = {};

  // ...........................................................................
  // Ready-node queues, indexed by Priority.index.
  //
  // These queues are an acceleration index over the prepared sets above:
  // whenever a node enters the prepared sets and is ready to produce, it is
  // also added to the queue matching its priority. _produce then picks the
  // next batch from these queues in O(batch) instead of rescanning all
  // prepared nodes on every cycle. The prepared sets remain the source of
  // truth: queue entries are hints that are re-validated (and re-bucketed
  // when a node's priority changed) before production.
  final List<Set<Node<dynamic>>> _readyNodes = [
    for (final _ in Priority.values) <Node<dynamic>>{},
  ];
  final List<Set<Node<dynamic>>> _readyInsertNodes = [
    for (final _ in Priority.values) <Node<dynamic>>{},
  ];

  // ...........................................................................
  // In-flight asynchronous productions, keyed by node (one per node).
  final Map<Node<dynamic>, Future<dynamic>> _asyncProductions = {};

  // ...........................................................................
  late GgOncePerCycle _schedulePreparation;
  void _initSchedulePreparation() {
    _schedulePreparation = GgOncePerCycle(
      task: _prepare,
      scheduleTask: _scheduleFast,
    );
  }

  // ...........................................................................
  late GgOncePerCycle _scheduleProductionDebouncer;
  void _initScheduleProduction() {
    _scheduleProductionDebouncer = GgOncePerCycle(
      task: _produce,
      scheduleTask: _scheduleNormal,
    );
  }

  // ...........................................................................
  late GgOncePerCycle _schedulePriorityUpdate;
  void _initSchedulePriorityUpdate() {
    _schedulePriorityUpdate = GgOncePerCycle(
      task: _updatePriorities,
      scheduleTask: _scheduleFast,
    );
  }

  // ...........................................................................
  void _initRootScope() {
    rootScope = Scope.root(key: 'root', scm: this);
  }

  // ...........................................................................
  void _initDisposed() {
    disposedItems = Disposed(scm: this);
  }

  // ...........................................................................
  bool get _preparedNodesAreEmpty =>
      _preparedNodes.isEmpty && _preparedInsertNodes.isEmpty;

  // ...........................................................................
  void _tick() {
    // Process also nodes with frame priority
    _minProductionPriority = Priority.frame;

    // Don't produce new frames if old items are still producing
    if (!_preparedNodesAreEmpty) {
      final isNotProducing = _producingNodes.isEmpty;
      if (isNotProducing) {
        _scheduleProduction();
      }

      return;
    }

    // Nominate all animated nodes. The counter lets animated nodes
    // distinguish tick-driven productions from productions triggered by a
    // supplier re-emission between ticks (see AnimatedNode.advance).
    _tickCount++;
    _nominatedNodes.addAll(_animatedNodes);

    // Start preparation
    _schedulePreparation.trigger();
  }

  // ...........................................................................
  void _initSuppliers() {
    // Init suppliers of new nodes
    for (final node in _nodesNeedingSupplierUpdate) {
      _addSuppliers(node, throwIfNotThere: false);
    }
    _nodesNeedingSupplierUpdate.clear();
  }

  // ...........................................................................
  void _initMissedSuppliers() {
    // If all previously prepared nodes have been processed
    // try again to prepare nodes that head missed suppliers before

    for (final node in _nodesWithMissedSuppliers) {
      _addSuppliers(node, throwIfNotThere: true);
    }

    _addPreparedNodes(_nodesWithMissedSuppliers);

    _nodesWithMissedSuppliers.clear();
  }

  // ...........................................................................
  void _addSuppliers(Node<dynamic> node, {required bool throwIfNotThere}) {
    // Collect all suppliers
    final suppliers = <String, Node<dynamic>>{};
    for (final supplierPath in node.bluePrint.suppliers) {
      final supplier = node.scope.findNode<dynamic>(
        supplierPath,
        excludedNodes: [node],
      );

      if (supplier == null) {
        if (throwIfNotThere) {
          throw ArgumentError(
            'Node "${node.path}": '
            'Supplier with key "$supplierPath" not found.',
          );
        } else {
          _nodesWithMissedSuppliers.add(node);
          _removePreparedNode(node);
          _nominatedNodes.remove(node);
          return;
        }
      }

      final supplierPathWithoutDots = supplierPath.startsWith('../')
          ? supplierPath.substring(3)
          : supplierPath;

      suppliers[supplierPathWithoutDots] = supplier;
    }

    // If all suppliers are found, add them to node
    node.initSuppliers(suppliers);
  }

  // ...........................................................................
  // Preparation

  /// Prepares all nodes
  void _prepare() {
    // Staging nodes can make queued customers unready
    _readyQueuesNeedRevalidation = true;

    // Init suppliers
    if (_nodesNeedingSupplierUpdate.isNotEmpty ||
        _nodesWithMissedSuppliers.isNotEmpty) {
      _initSuppliers();
    }

    // For all nominated nodes
    for (var node in [...nominatedNodes]) {
      // Prepare node
      _prepareNode(node);
    }

    // All nominated nodes have been prepared.
    // Add it to prepared nodes
    _addPreparedNodes(_nominatedNodes);

    // Clear nominated nodes
    _nominatedNodes.clear();

    // Start production
    _scheduleProduction();
  }

  // ...........................................................................
  /// Prepares a node and its customers
  ///
  /// Implemented iteratively with an explicit stack: the customer graph can
  /// be deeper than the call stack allows (a recursive implementation
  /// overflows on chains of a few thousand nodes).
  void _prepareNode(Node<dynamic> node) {
    final stack = <Node<dynamic>>[node];

    while (stack.isNotEmpty) {
      final current = stack.removeLast();

      // Node is already prepared?
      final isAlreadyPrepared = !current.needsPreparation();
      if (isAlreadyPrepared) {
        continue;
      }

      // Nodes needs preparation? Prepare.
      current.prepare();

      // Prepare all inserts
      for (final insert in current.inserts) {
        stack.add(insert);
      }

      // If node is a insert
      if (current is Insert) {
        _prepareInsert(current, stack);
      }

      // Prepare also all customers
      for (final customer in current.customers) {
        stack.add(customer);
      }
    }
  }

  // ...........................................................................
  void _prepareInsert(Insert<dynamic> node, List<Node<dynamic>> stack) {
    // Last insert? Prepare also host's customers
    if (node.isLastInsert) {
      for (final customer in node.host.customers) {
        stack.add(customer);
      }
    }
    // Not last insert? Prepare the following inserts
    else {
      bool isLaterInsert = false;
      for (final insert in node.host.inserts) {
        if (insert == node) {
          isLaterInsert = true;
          continue;
        }
        if (isLaterInsert) {
          stack.add(insert);
        }
      }
    }
  }

  // ...........................................................................
  // Have realtime nodes?
  /// Returns true if real time nodes are currently prepared
  bool get _preparedRealtimeNodesExist => _preparedRealtimeNodes.isNotEmpty;

  // ...........................................................................
  // Process fast, when realtime nodes are prepared

  void _scheduleProduction() {
    final schedule = _preparedRealtimeNodesExist
        ? _scheduleFast
        : _scheduleNormal;
    _scheduleProductionDebouncer.trigger(scheduleTask: schedule);
  }

  // ...........................................................................
  // Production

  /// Produce all nodes
  void _produce() {
    // _assertNoNodeIsErased(nodes: _preparedNodes);
    if (_preparedNodesAreEmpty) {
      return;
    }

    // Start timeout timer
    if (shouldTimeOut) {
      _startTimeoutCheck();
    }

    // Drop stale queue entries and move nodes whose priority has changed
    // since they became ready into the right queue.
    _revalidateReadyQueues();

    var produced = _produceNextBatch();

    // In drain mode all waves becoming ready are processed within this
    // cycle instead of scheduling one event-loop task per wave.
    while (drainMode &&
        produced &&
        _producingNodes.isEmpty &&
        !_preparedNodesAreEmpty) {
      produced = _produceNextBatch();
    }
  }

  // ...........................................................................
  /// Produces the next batch of ready nodes.
  ///
  /// Processes only nodes of one priority level, making sure that all nodes
  /// of a given priority are processed before the others start. Returns
  /// true if a batch was produced.
  bool _produceNextBatch() {
    // Process nodes grouped by priority
    for (final priority in Priority.values.reversed) {
      // Don't process priorities below minimum production priority
      if (priority.value < _minProductionPriority.value) {
        continue;
      }

      // Get nodes that have the desired priority
      // Process inserts first
      final insertQueue = _readyInsertNodes[priority.index];
      final queue = insertQueue.isNotEmpty
          ? insertQueue
          : _readyNodes[priority.index];

      // Continue if no such nodes are available
      if (queue.isEmpty) {
        continue;
      }

      final batch = [...queue];
      queue.clear();
      _produceBatch(batch);
      return true;
    }

    // Fallback: The queues are empty, but prepared nodes exist. This happens
    // e.g. when nodes were put into the prepared sets from outside without
    // going through _addPreparedNodes. Fall back to scanning the prepared
    // sets like the queues never existed. Ready nodes found here are rare;
    // the scan keeps the queue optimization safe without changing behavior.
    for (final priority in Priority.values.reversed) {
      if (priority.value < _minProductionPriority.value) {
        continue;
      }

      final insertsReadyToProduce = _readyNodesOfPriority(
        _preparedInsertNodes,
        priority,
      );

      final nodesOfPriority = insertsReadyToProduce.isNotEmpty
          ? insertsReadyToProduce
          : _readyNodesOfPriority(_preparedNodes, priority);

      if (nodesOfPriority.isEmpty) {
        continue;
      }

      _produceBatch([...nodesOfPriority]);
      return true;
    }

    return false;
  }

  // ...........................................................................
  /// Returns the nodes of [nodes] that are ready to produce with [priority]
  Iterable<Node<dynamic>> _readyNodesOfPriority(
    Set<Node<dynamic>> nodes,
    Priority priority,
  ) {
    return nodes.where((n) => n.isReadyToProduce && n.priority == priority);
  }

  // ...........................................................................
  /// Produces a batch of nodes of one priority level
  void _produceBatch(List<Node<dynamic>> batch) {
    for (final node in batch) {
      // Disposed nodes must not produce. Remove them from the prepared
      // sets - otherwise they would keep the production pipeline open.
      // Nodes can be disposed while their own batch is producing.
      // coverage:ignore-start
      if (node.isDisposed) {
        _removePreparedNode(node);
        continue;
      }
      // coverage:ignore-end

      // Remove node from preparedNodes
      _removePreparedNode(node);

      // Reset timeout state
      node.isTimedOut = false;
      node.productionStartTime = _stopwatch.elapsed;

      assert(node.isReadyToProduce);

      // Add node to producing nodes
      _producingNodes.add(node);
      node.produce();
    }
  }

  // ...........................................................................
  /// Removes stale entries from the ready queues and moves entries whose
  /// priority changed since enqueueing into the queue of their current
  /// priority.
  ///
  /// A queue entry is stale when the node was disposed, left the prepared
  /// sets, or is no longer ready to produce (e.g. because a supplier was
  /// re-nominated). Nodes becoming ready again are re-enqueued by
  /// _addPreparedNodes when their supplier finalizes.
  void _revalidateReadyQueues() {
    // Only revalidate when something happened that can invalidate queue
    // entries (see _readyQueuesNeedRevalidation call sites). _produceBatch
    // additionally re-checks every node before producing it.
    if (!_readyQueuesNeedRevalidation) {
      return;
    }
    _readyQueuesNeedRevalidation = false;

    _revalidateReadyQueuesOfKind(_readyInsertNodes, _preparedInsertNodes);
    _revalidateReadyQueuesOfKind(_readyNodes, _preparedNodes);
  }

  /// Set to true whenever an event occurs that can make ready queue entries
  /// stale: preparing nodes (stages suppliers of queued nodes), priority
  /// changes (queue assignment), disposals and removals from the prepared
  /// sets, and supplier re-initializations.
  bool _readyQueuesNeedRevalidation = true;

  void _revalidateReadyQueuesOfKind(
    List<Set<Node<dynamic>>> queues,
    Set<Node<dynamic>> preparedNodes,
  ) {
    for (var i = 0; i < queues.length; i++) {
      final queue = queues[i];
      if (queue.isEmpty) {
        continue;
      }

      List<Node<dynamic>>? movedNodes;

      queue.removeWhere((node) {
        if (node.isDisposed ||
            !preparedNodes.contains(node) ||
            !node.isReadyToProduce) {
          return true;
        }

        if (node.priority.index != i) {
          (movedNodes ??= []).add(node);
          return true;
        }

        return false;
      });

      if (movedNodes != null) {
        for (final node in movedNodes!) {
          queues[node.priority.index].add(node);
        }
      }
    }
  }

  // ...........................................................................
  void _addPreparedNodes(Iterable<Node<dynamic>> nodes) {
    for (final node in nodes) {
      // Disposed nodes can never produce
      if (node.isDisposed) {
        continue;
      }

      if (node.isInsert) {
        _preparedInsertNodes.add(node);
      } else {
        _preparedNodes.add(node);
      }

      final priority = node.priority;

      if (priority == Priority.realtime) {
        _preparedRealtimeNodes.add(node);
      }

      // Nodes that are ready to produce are added to the matching ready
      // queue. Nodes that are not ready yet will be re-added when their
      // supplier finalizes production (_finalizeProduction).
      if (node.isReadyToProduce) {
        final queues = node.isInsert ? _readyInsertNodes : _readyNodes;
        queues[priority.index].add(node);
      }
    }
  }

  void _removePreparedNode(Node<dynamic> node) {
    // Also drop the node's ready queue entry. Otherwise a node re-enqueued
    // while its batch is still producing (e.g. an insert whose input
    // finalizes mid-batch) would keep a stale entry and produce twice.
    // Entries queued under an outdated priority are cleaned up by
    // _revalidateReadyQueues (priority changes set
    // _readyQueuesNeedRevalidation).
    if (node.isInsert) {
      _preparedInsertNodes.remove(node);
      _readyInsertNodes[node.priority.index].remove(node);
    } else {
      _preparedNodes.remove(node);
      _readyNodes[node.priority.index].remove(node);
    }

    if (node.priority == Priority.realtime) {
      _preparedRealtimeNodes.remove(node);
    }
  }

  // ...........................................................................
  void _finalizeProduction(Node<dynamic> node, {bool propagate = true}) {
    // Remove node from producing nodes
    _producingNodes.remove(node);

    // Reset production state
    node.finalizeProduction();

    if (propagate) {
      // Inserts now need to produce
      _addPreparedNodes(node.inserts);

      // Customers now need to produce
      _addPreparedNodes(node.customers);

      // If node is a insert
      _finalizeInsert(node);
    } else {
      // The production wave ends here. _prepareNode staged the node's
      // transitive customers before this production; un-stage every one
      // that no other pending wave will produce. Otherwise they would
      // stay staged forever and block every future wave running through
      // them (their customers would never become isReadyToProduce).
      _unstageSkippedNodes(node);
    }

    // Schedule production
    _scheduleProduction();

    if (_preparedNodesAreEmpty) {
      _initMissedSuppliers();
    }

    // Everything is done?
    if (_preparedNodesAreEmpty) {
      _resetMinimumProductionPriority();
      _stopTimeoutCheck();
    }
  }

  // ...........................................................................
  /// Un-stages the transitive customers of [node] that were staged for the
  /// wave ending at [node] and that no other pending wave will finalize.
  ///
  /// Mirrors the traversal of [_prepareNode]. Nodes that are nominated,
  /// prepared or producing are owed a production by another wave which will
  /// finalize (and thereby un-stage) them - those are left untouched.
  void _unstageSkippedNodes(Node<dynamic> node) {
    final stack = <Node<dynamic>>[...node.inserts, ...node.customers];
    var unstagedNodes = false;

    while (stack.isNotEmpty) {
      final current = stack.removeLast();

      if (!current.isStaged) {
        continue;
      }

      // Owed a production by another pending wave? Leave it staged.
      if (_nominatedNodes.contains(current) ||
          _preparedNodes.contains(current) ||
          _preparedInsertNodes.contains(current) ||
          _producingNodes.contains(current)) {
        continue;
      }

      current.finalizeProduction();
      unstagedNodes = true;

      for (final insert in current.inserts) {
        stack.add(insert);
      }

      if (current is Insert) {
        _prepareInsert(current, stack);
      }

      for (final customer in current.customers) {
        stack.add(customer);
      }
    }

    // Un-staging changes readiness of already queued nodes
    if (unstagedNodes) {
      _readyQueuesNeedRevalidation = true;
    }
  }

  // ...........................................................................
  void _finalizeInsert(Node<dynamic> node) {
    if (node is Insert) {
      // If node is the last insert, host's customers need to produce
      if (node.isLastInsert) {
        _addPreparedNodes(node.host.customers);
      }
      // Otherwise the output node needs to produce
      else {
        _addPreparedNodes([node.output]);
      }
    }
  }

  // ...........................................................................
  // Priority handling

  /// By default, only real-time nodes are processed directly.
  /// Other nodes are processed by special triggers, e.g., tick().
  /// These triggers will lower the _minProductionPriority in order
  /// to allow processing of other priorities as well.
  Priority _minProductionPriority = Priority.realtime;

  /// Sets back minimum production priority
  void _resetMinimumProductionPriority() {
    _minProductionPriority = Priority.realtime;
  }

  /// Nodes whose priority changed since the last priority update
  final Set<Node<dynamic>> _nodesWithChangedPriority = {};

  /// Update priorities of all nodes affected by a priority change.
  ///
  /// A node's priority can only affect its transitive suppliers (they take
  /// over the highest customer priority). So instead of resetting and
  /// recomputing the whole graph, only the supplier cone of the changed
  /// nodes is invalidated and recomputed.
  void _updatePriorities() {
    if (_nodesWithChangedPriority.isEmpty) {
      return;
    }

    // Collect the supplier cone of all changed nodes
    final cone = <Node<dynamic>>{};
    final stack = <Node<dynamic>>[..._nodesWithChangedPriority];
    _nodesWithChangedPriority.clear();

    while (stack.isNotEmpty) {
      final node = stack.removeLast();
      if (!cone.add(node)) {
        continue;
      }
      stack.addAll(node.suppliers);
    }

    // Reset the assigned priorities within the cone
    for (final node in cone) {
      node.customerPriority = null;
    }

    // Recompute the priorities within the cone. Nodes outside the cone
    // keep their values - they cannot be affected by the change.
    for (final node in cone) {
      _updatePriorityForNode(node);
    }
  }

  // ..........................................................................
  /// Update the priority of [root] from its customers' priorities.
  ///
  /// Iterative with an explicit stack: the recursion depth would equal the
  /// customer chain length and overflow on deep chains. Customers without a
  /// computed priority are computed on demand; already computed customers
  /// (customerPriority != null) are taken as is.
  void _updatePriorityForNode(Node<dynamic> root) {
    final stack = <Node<dynamic>>[root];

    while (stack.isNotEmpty) {
      final node = stack.last;

      // Has already a priority? Return.
      if (node.customerPriority != null) {
        stack.removeLast();
        continue;
      }

      // Update priority for customers first
      var allCustomersComputed = true;
      var highestChildPriority = Priority.lowest;

      for (final customer in node.customers) {
        if (customer.customerPriority == null) {
          stack.add(customer);
          allCustomersComputed = false;
        }
        // Take over highest priority
        else if (customer.priority.value > highestChildPriority.value) {
          highestChildPriority = customer.priority;
        }
      }

      // Assign highest priority to itself
      if (allCustomersComputed) {
        node.customerPriority = highestChildPriority;
        stack.removeLast();
      }
    }
  }

  // ...........................................................................
  // Handle timeouts

  /// This stopwatch is used to estimate milliseconds when not given
  late Stopwatch _stopwatch;
  // ...........................................................................
  /// Initializes a function returning elapsed milliseconds
  void _initStopWatch() {
    _stopwatch = isTest ? _testCreateStopWatch() : Stopwatch();
    _stopwatch.start();
  }

  /// Timeout interval: Nodes must not use more then 5ms for production
  final Duration timeout = const Duration(milliseconds: 5);

  /// Timer used to check for timeouts
  Timer? _timeoutCheckTimer;

  // ...........................................................................
  /// Starts an interval timer checking for production timeouts
  ///
  /// If a check timer is already running it is reused. Previously a new
  /// periodic timer was created on every production cycle without
  /// cancelling the old one, leaking one timer per cycle.
  void _startTimeoutCheck() {
    if (_timeoutCheckTimer != null) {
      return;
    }

    final interval = Duration(milliseconds: timeout.inMilliseconds ~/ 2);

    if (isTest) {
      _testTimer = GgFakeTimer.periodic(interval, _checkForTimeouts);
      _timeoutCheckTimer = _testTimer;
    } else {
      _timeoutCheckTimer = Timer.periodic(interval, _checkForTimeouts);
      _testTimer = null;
    }
  }

  // ...........................................................................
  /// Stops interval timer checking for production timeouts
  void _stopTimeoutCheck() {
    _timeoutCheckTimer?.cancel();
    _timeoutCheckTimer = null;
    _testTimer = null;
  }

  // ...........................................................................
  /// Checks for timeouts
  void _checkForTimeouts(Timer timer) {
    // No producing nodes? Finish check.
    if (_producingNodes.isEmpty) {
      _stopTimeoutCheck(); // coverage:ignore-line
    }

    // Iterate all producing nodes
    for (final node in [..._producingNodes]) {
      // If a nodes production duration exceeds its timeout duration,
      // (the node's own productionTimeout, defaulting to the global timeout)
      final currentTime = _stopwatch.elapsed;
      final isTimeout =
          currentTime - node.productionStartTime >= node.productionTimeout;

      // mark node as timed out
      if (isTimeout) {
        node.isTimedOut = true;
        _finalizeProduction(node);
      }
    }
  }

  // ...........................................................................
  // Test helpers
  final List<void Function()> _testNormalTasks = [];
  final List<void Function()> _testFastTasks = [];

  void _testScheduleNormal(void Function() task) {
    _testNormalTasks.add(task);
  }

  void _testScheduleFast(void Function() task) {
    _testFastTasks.add(task);
  }

  void _testRunNormalTasks() {
    var tasksCopy = [..._testNormalTasks];
    _testNormalTasks.clear();
    for (final task in tasksCopy) {
      task();
    }
  }

  void _testRunFastTasks() {
    var tasksCopy = [..._testFastTasks];
    _testFastTasks.clear();
    for (final task in tasksCopy) {
      task();
    }
  }

  GgFakeTimer? _testTimer;
  late GgFakeStopwatch _testStopwatch;

  // ...........................................................................
  void _assertNodeIsNotErased(Node<dynamic> node) {
    if (!extraChecks) {
      return;
    }

    assert(
      !node.isErased,
      '${node.scope}/${node.key} with id ${node.id} is disposed.',
    );
  }

  // ...........................................................................
  void _connectNewSmartNodeToPotentialMasters(
    Node<dynamic> smartNode, {
    Node<dynamic>? newPotentialMaster,
  }) {
    // Evaluate the new potential master
    if (newPotentialMaster != null) {
      // New master could not be master? Return.
      final couldBeMaster = newPotentialMaster.couldBeMasterOf(smartNode);
      if (!couldBeMaster) {
        return;
      }

      // New potential master is already master? Return.
      if (!newPotentialMaster.isDisposed &&
          smartNode.suppliers.contains(newPotentialMaster)) {
        return;
      }
    }

    // Find the master node
    final masterNode = smartNode.findSmartMaster();

    // No master node found? Reset and return.
    if (masterNode == null || masterNode.isDisposed) {
      smartNode.needsInitSuppliers();
      smartNode.resetSmartNodeReplacements();
      return;
    }

    // Already connected? Do nothing.
    if (smartNode.suppliers.contains(masterNode)) {
      return;
    }

    // Reset smartNode replacements
    smartNode.resetSmartNodeReplacements();

    // If a replacement is available,
    // link smartNode to replacement
    smartNode.addSmartNodeReplacement(
      smartNode.bluePrint.connectSupplier(masterNode.path),
    );

    // Init suppliers
    smartNode.needsInitSuppliers();
  }

  // ...........................................................................
  void _connectNewMasterNodeToPotentialSmartNodes(Node<dynamic> newMaster) {
    // Only smart nodes whose master path ends with the new master's key
    // can connect to it.
    final smartNodes = _smartNodesByMasterKey[newMaster.key];
    if (smartNodes == null) {
      return;
    }

    for (final smartNode in [...smartNodes]) {
      _connectNewSmartNodeToPotentialMasters(
        smartNode,
        newPotentialMaster: newMaster,
      );
    }
  }

  // ...........................................................................
  void _updateSmartNodes(Node<dynamic> node) {
    // Node is a smartNode?
    if (node.isSmartNode) {
      // Add the node to list of smartNodes.
      if (node.isDisposed) {
        _removeSmartNode(node);
        return;
      }

      _addSmartNode(node);
      _connectNewSmartNodeToPotentialMasters(node);

      return;
    }

    // Node is a master node? Update smartNodes
    _connectNewMasterNodeToPotentialSmartNodes(node);
  }
}
