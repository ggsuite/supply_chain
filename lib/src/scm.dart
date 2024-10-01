// @license
// Copyright (c) 2019 - 2023 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:async' show scheduleMicrotask, Timer;
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
  Scm({
    this.isTest = false,
  }) {
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
    return _nodes
        .whereType<Node<T>>()
        .where((element) => element.key == key)
        .map((e) => e);
  }

  /// Adds a node to scm
  void addNode(Node<dynamic> node) {
    _assertNodeIsNotErased(node);
    _nodes.add(node);

    nominate(node);
  }

  /// Removes the node from scm
  void removeNode(Node<dynamic> node) {
    _nodes.remove(node);
    _animatedNodes.remove(node);
    _nominatedNodes.remove(node);
    _removePreparedNode(node);
    _producingNodes.remove(node);
    _smartNodes.remove(node);
    _nodesWithMissedSuppliers.remove(node);
    _nodesNeedingSupplierUpdate.remove(node);
  }

  /// Adds node for initialization of suppliers
  void needsInitSuppliers(Node<dynamic> node) {
    _nodesNeedingSupplierUpdate.add(node);
  }

  /// Nominate node for production
  void nominate(Node<dynamic> node) {
    // If the node has no customers, it is more efficient to produce it directly
    if (node.isReadyToProduce &&
        node.suppliers.isEmpty &&
        node.customers.isEmpty &&
        node.inserts.isEmpty &&
        node.isInitialized &&
        !node.isInsert &&
        !node.isDisposed) {
      node.produce(announce: false, triggerOnChange: true);
      node.finalizeProduction();
      return;
    }

    _assertNodeIsNotErased(node);
    _nominatedNodes.add(node);
    _schedulePreparation.trigger();
  }

  /// Inform scm about an update
  void hasNewProduct(Node<dynamic> node, {bool? extraChecks}) {
    // Node is not in producing nodes?
    // Throw an exception. Only producing nodes should call hasNewProduct()
    final check = extraChecks ?? Scm.extraChecks;
    if (check && !_producingNodes.contains(node)) {
      throw StateError('Node "$node" did call "hasNewProduct()" '
          'without being nominated before.');
    }

    // Finalize production
    _finalizeProduction(node);
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
  }

  // ...........................................................................
  // Timeouts

  /// Set this property to true, if production timeouts should block
  bool shouldTimeOut = true;

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
  void testFlushTasks({bool tick = true}) {
    if (tick) {
      _tick();
    }

    while (_testFastTasks.isNotEmpty ||
        _testNormalTasks.isNotEmpty ||
        _nodesNeedingSupplierUpdate.isNotEmpty) {
      testRunNormalTasks();
      testRunFastTasks();

      if (tick && !_preparedNodesAreEmpty) {
        _tick();
      }
    }

    _initMissedSuppliers();
  }

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
  // Nodes
  final Set<Node<dynamic>> _nodes = {};
  final Set<Node<dynamic>> _animatedNodes = {};

  // ...........................................................................
  final Set<Node<dynamic>> _nodesNeedingSupplierUpdate = {};
  final Set<Node<dynamic>> _nodesWithMissedSuppliers = {};

  // ...........................................................................
  final Set<Node<dynamic>> _smartNodes = {};

  // ...........................................................................
  // Processing stages
  final Set<Node<dynamic>> _nominatedNodes = {};
  final Set<Node<dynamic>> _preparedNodes = {};
  final Set<Node<dynamic>> _preparedInsertNodes = {};
  final Set<Node<dynamic>> _preparedRealtimeNodes = {};
  final Set<Node<dynamic>> _producingNodes = {};

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

    // Nominate all animated nodes
    _nominatedNodes.addAll(_animatedNodes);

    // Start preparation
    _schedulePreparation.trigger();
  }

  // ...........................................................................
  void _initSuppliers() {
    // Init suppliers of new nodes
    for (final node in _nodesNeedingSupplierUpdate) {
      _addSuppliers(
        node,
        throwIfNotThere: false,
      );
    }
    _nodesNeedingSupplierUpdate.clear();
  }

  // ...........................................................................
  void _initMissedSuppliers() {
    // If all previously prepared nodes have been processed
    // try again to prepare nodes that head missed suppliers before

    for (final node in _nodesWithMissedSuppliers) {
      _addSuppliers(
        node,
        throwIfNotThere: true,
      );
    }

    _addPreparedNodes(_nodesWithMissedSuppliers);

    _nodesWithMissedSuppliers.clear();
  }

  // ...........................................................................
  void _addSuppliers(
    Node<dynamic> node, {
    required bool throwIfNotThere,
  }) {
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

      suppliers[supplierPath] = supplier;
    }

    // If all suppliers are found, add them to node
    node.initSuppliers(suppliers);
  }

  // ...........................................................................
  // Preparation

  /// Prepares all nodes
  void _prepare() {
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
  void _prepareNode(Node<dynamic> node) {
    // Node is already prepared?
    final isAlreadyPrepared = !node.needsPreparation();
    if (isAlreadyPrepared) {
      return;
    }

    // Nodes needs preparation? Prepare.
    node.prepare();

    // Prepare all inserts
    for (final insert in node.inserts) {
      _prepareNode(insert);
    }

    // If node is a insert
    if (node is Insert) {
      _prepareInsert(node);
    }

    // Prepare also all customers
    for (final customer in node.customers) {
      _prepareNode(customer);
    }
  }

  // ...........................................................................
  void _prepareInsert(Insert<dynamic> node) {
    // Last insert? Prepare also host's customers
    if (node.isLastInsert) {
      for (final customer in node.host.customers) {
        _prepareNode(customer);
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
          _prepareNode(insert);
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
    final schedule =
        _preparedRealtimeNodesExist ? _scheduleFast : _scheduleNormal;
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

    // Remove disposed nodes
    _preparedNodes.removeWhere((n) => n.isDisposed);
    _preparedInsertNodes.removeWhere((n) => n.isDisposed);
    _preparedRealtimeNodes.removeWhere((n) => n.isDisposed);

    // Start timeout timer
    if (!_preparedNodesAreEmpty && shouldTimeOut) {
      _startTimeoutCheck();
    }

    // Process nodes grouped by priority
    for (final priority in Priority.values.reversed) {
      // Don't process priorities below minimum production priority
      if (priority.value < _minProductionPriority.value) {
        continue;
      }

      // Get nodes that have the desired priority
      // Process inserts first
      final insertsReadyToProduce = _preparedInsertNodes.where(
        (n) => n.isReadyToProduce && n.priority == priority,
      );

      final nodesOfPriority = insertsReadyToProduce.isNotEmpty
          ? insertsReadyToProduce
          : _preparedNodes.where(
              (n) => n.isReadyToProduce && n.priority == priority,
            );

      // Continue if no such nodes are available
      if (nodesOfPriority.isEmpty) {
        continue;
      }

      for (final node in [...nodesOfPriority]) {
        // Remove node from preparedNodes
        _removePreparedNode(node);

        // Reset timeout state
        node.isTimedOut = false;
        node.productionStartTime = _stopwatch.elapsed;

        assert(node.isReadyToProduce);

        // Produce
        if (!node.isDisposed) {
          // Add node to producing nodes
          _producingNodes.add(node);
          node.produce();
        }
      }

      // We process only nodes of one priority level in a cycle.
      // Thus we are making sure that all nodes of a given priority are
      // processed before the others start.
      return;
    }
  }

  // ...........................................................................
  void _addPreparedNodes(Iterable<Node<dynamic>> nodes) {
    if (nodes.isEmpty) {
      return;
    }

    for (final node in nodes) {
      if (node.isInsert) {
        _preparedInsertNodes.add(node);
      } else {
        _preparedNodes.add(node);
      }
    }

    _preparedRealtimeNodes.addAll(
      nodes.where((n) => n.priority == Priority.realtime),
    );
  }

  void _removePreparedNode(Node<dynamic> node) {
    if (node.isInsert) {
      _preparedInsertNodes.remove(node);
    } else {
      _preparedNodes.remove(node);
    }

    if (node.priority == Priority.realtime) {
      _preparedRealtimeNodes.remove(node);
    }
  }

  // ...........................................................................
  void _finalizeProduction(Node<dynamic> node) {
    // Remove node from producing nodes
    _producingNodes.remove(node);

    // Reset production state
    node.finalizeProduction();

    // Inserts now need to produce
    _addPreparedNodes(node.inserts);

    // Customers now need to produce
    _addPreparedNodes(node.customers);

    // If node is a insert
    _finalizeInsert(node);

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

  /// Update priorities of all nodes
  void _updatePriorities() {
    // Reset all assigned priorities
    _resetPriorities();

    // Update priorities for all nodes
    for (final node in nodes) {
      _updatePriorityForNode(node);
    }
  }

  // ..........................................................................
  /// Resets priority for node
  void _resetPriorities() {
    for (final node in nodes) {
      node.customerPriority = null;
    }
  }

  // ..........................................................................
  /// Update priorities
  void _updatePriorityForNode(Node<dynamic> node) {
    // Has already a priority? Return.
    if (node.customerPriority != null) {
      return;
    }

    // Update priority for customers first
    var highestChildPriority = Priority.lowest;

    for (final customer in node.customers) {
      _updatePriorityForNode(customer);

      // Take over highest priority
      if (customer.priority.value > highestChildPriority.value) {
        highestChildPriority = customer.priority;
      }
    }

    // Assign highest priority to itself
    node.customerPriority = highestChildPriority;
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
  void _startTimeoutCheck() {
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
      // If a nodes production duration exceeds timeout duration,
      final currentTime = _stopwatch.elapsed;
      final isTimeout = currentTime - node.productionStartTime >= timeout;

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
    final masterNode = smartNode.findMasterNode();

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
      smartNode.bluePrint.connectSupplier(
        masterNode.path,
      ),
    );

    // Init suppliers
    smartNode.needsInitSuppliers();
  }

  // ...........................................................................
  void _connectNewMasterNodeToPotentialSmartNodes(Node<dynamic> newMaster) {
    // Connect each smart node to the new master

    for (final smartNode in _smartNodes) {
      _connectNewSmartNodeToPotentialMasters(
        smartNode,
        newPotentialMaster: newMaster,
      );
    }
  }

  // ...........................................................................
  void _updateSmartNodes(
    Node<dynamic> node,
  ) {
    // Node is a smartNode?
    if (node.isSmartNode) {
      // Add the node to list of smartNodes.
      if (node.isDisposed) {
        _smartNodes.remove(node);
        return;
      }

      _smartNodes.add(node);
      _connectNewSmartNodeToPotentialMasters(node);

      return;
    }

    // Node is a master node? Update smartNodes
    _connectNewMasterNodeToPotentialSmartNodes(node);
  }
}
