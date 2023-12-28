// @license
// Copyright (c) 2019 - 2023 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:async' show scheduleMicrotask, Timer;
import 'package:gg_fake_stopwatch/gg_fake_stopwatch.dart';
import 'package:gg_fake_timer/gg_fake_timer.dart';
import 'package:gg_once_per_cycle/gg_once_per_cycle.dart';

import 'node.dart';
import 'priority.dart';
import 'schedule_task.dart';
import 'scm_node_interface.dart';

/// SCM - Supply Chain Manager: Controls the data flow in the supply chain.
class Scm implements ScmNodeInterface {
  // ######################
  // Public
  // ######################

  // ...........................................................................
  Scm({
    this.isTest = false,
  }) {
    _init();
  }

  // ...........................................................................
  /// Default supply chain manager
  static final Scm testInstance = Scm(isTest: true);

  // ...........................................................................
  // ScmNodeInterface

  /// Returns iterable of all nodes
  Iterable<Node> get nodes => _nodes;

  /// Adds a node to scm
  @override
  void addNode(Node node) {
    _nodes.add(node);
    nominate(node);
  }

  /// Removes the node from scm
  @override
  void removeNode(Node node) => _nodes.remove(node);

  /// Nominate node for production
  @override
  void nominate(Node node) {
    _nominatedNodes.add(node);
    _schedulePreparation.trigger();
  }

  /// Inform scm about an update
  @override
  void hasNewProduct(Node node) {
    // Node is not in producing nodes?
    // Throw an exception. Only producing nodes should call hasNewProduct()
    if (!_producingNodes.contains(node)) {
      throw StateError('Node "$node" did call "hasNewProduct()" '
          'without being nominated before.');
    }

    // Finalize production
    _finalizeProduction(node);
  }

  // ...........................................................................
  // Animation

  /// Returns currently animated nodes
  Iterable<Node> get animatedNodes => _animatedNodes;

  /// Starts to animate node
  @override
  void animateNode(Node node) => _animatedNodes.add(node);

  /// Stops to animate node
  @override
  void deanimateNode(Node node) => _animatedNodes.remove(node);

  /// Call this method to trigger animation frame calculation
  void tick() => _tick();

  // ...........................................................................
  // Product live cycle

  // List of nodes, nominated for production
  Iterable<Node> get nominatedNodes => _nominatedNodes;

  // List of nodes, prepared for production
  Iterable<Node> get preparedNodes => _preparedNodes;

  // ...........................................................................
  // Priority
  @override
  void priorityHasChanged(Node node) {
    _schedulePriorityUpdate.trigger();
  }

  /// Nodes with a priority below this priority are not processed
  Priority get minProductionPriority => _minProductionPriority;

  // ...........................................................................
  // Cleanup
  void clear() {
    _nominatedNodes.clear();
    _preparedNodes.clear();
    _producingNodes.clear();
  }

  // ...........................................................................
  // Timeouts

  /// Set this property to true, if production timeouts should block
  bool shouldTimeOut = true;

  // ...........................................................................
  // Print graph

  /// Returns a graph that can be turned into svg using graphviz
  String get graph => _graph;

  // ######################
  // Testing
  // ######################

  /// Is used for testing
  final bool isTest;

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
  void testFlushTasks() {
    while (_testFastTasks.isNotEmpty || _testNormalTasks.isNotEmpty) {
      testRunNormalTasks();
      testRunFastTasks();
    }
  }

  /// Clears all scheduled tasks
  void testClearScheduledTasks() {
    _testNormalTasks.clear();
    _testFastTasks.clear();
  }

  // ...........................................................................
  // Test timers

  GgFakeTimer? get testTimer => _testTimer;
  GgFakeStopwatch get testStopwatch => _testStopwatch;

  Stopwatch _testCreateStopWatch() {
    _testStopwatch = GgFakeStopwatch();
    return _testStopwatch;
  }

  // ######################
  // Private
  // ######################

  // ...........................................................................
  void _init() {
    _initStopWatch();
    _initSchedulePreparation();
    _initScheduleProduction();
    _initSchedulePriorityUpdate();
  }

  // ...........................................................................
  void Function(Task) get _scheduleFast =>
      isTest ? _testScheduleFast : scheduleMicrotask;

  void Function(Task) get _scheduleNormal =>
      isTest ? _testScheduleNormal : Future.microtask;

  // ...........................................................................
  // Nodes
  final Set<Node> _nodes = {};
  final Set<Node> _animatedNodes = {};

  // ...........................................................................
  // Processing stages
  final Set<Node> _nominatedNodes = {};
  final Set<Node> _preparedNodes = {};
  final Set<Node> _producingNodes = {};

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
  void _tick() {
    // Process also nodes with frame priority
    _minProductionPriority = Priority.frame;

    // Don't produce new frames if old items are still producing
    if (_preparedNodes.isNotEmpty) {
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
  // Preparation

  /// Prepares all nodes
  void _prepare() {
    // For all nominated nodes
    for (var node in [...nominatedNodes]) {
      // Does node need update?
      final needsUpdate = node.needsUpdate;

      // If node needs no update, continue
      if (!needsUpdate) {
        continue;
      }

      // Prepare node
      _prepareNode(node);
    }

    // All nominated nodes have been prepared.
    // Add it to prepared nodes
    _preparedNodes.addAll(_nominatedNodes);

    // Clear nominated nodes
    _nominatedNodes.clear();

    // Start production
    _scheduleProduction();
  }

  // ...........................................................................
  /// Prepares a node and its customers
  void _prepareNode(Node node) {
    // Node is already prepared?
    final isAlreadyPrepared = !node.needsPreparation();
    if (isAlreadyPrepared) {
      return;
    }

    // Nodes needs preparation? Prepare.
    node.prepare();

    // Prepare also all customers
    for (final customer in node.customers) {
      _prepareNode(customer);
    }
  }

  // ...........................................................................
  // Have realtime nodes?
  bool get realtimeNodesArePrepared => _preparedNodes.any(
        (element) => element.priority.value >= Priority.realtime.value,
      );

  // ...........................................................................
  // Process fast, when realtime nodes are prepared

  void _scheduleProduction() {
    final schedule = realtimeNodesArePrepared ? _scheduleFast : _scheduleNormal;
    _scheduleProductionDebouncer.trigger(scheduleTask: schedule);
  }

  // ...........................................................................
  // Production

  /// Produce all nodes
  void _produce() {
    // For all nodes that are ready to produce
    final nodesReadyToProduce = preparedNodes
        .where(
          (n) => n.isReadyToProduce,
        )
        .toList();

    // Start timeout timer
    if (nodesReadyToProduce.isNotEmpty && shouldTimeOut) {
      _startTimeoutCheck();
    }

    // Process nodes grouped by priority
    for (final priority in Priority.values.reversed) {
      // Don't process priorities below minimum production priority
      if (priority.value < _minProductionPriority.value) {
        continue;
      }

      // Get nodes that have the desired priority
      final nodesOfPriority = nodesReadyToProduce.where(
        (element) => element.priority == priority,
      );

      // Continue if no such nodes are available
      if (nodesOfPriority.isEmpty) {
        continue;
      }

      for (final node in nodesOfPriority) {
        // Remove node from preparedNodes
        _preparedNodes.remove(node);

        // Add node to producing nodes
        _producingNodes.add(node);

        // Reset timeout state
        node.isTimedOut = false;
        node.productionStartTime = _stopwatch.elapsed;

        // Produce
        node.produce();
      }

      // We process only nodes of one priority level in a cycle.
      // Thus we are making sure that all nodes of a given priority are
      // processed before the others start.
      return;
    }
  }

  // ...........................................................................
  void _finalizeProduction(Node node) {
    // Remove node from producing nodes
    _producingNodes.remove(node);

    // Reset production state
    node.finalizeProduction();

    // Customers now need to produce
    _preparedNodes.addAll(node.customers);
    _scheduleProduction();

    // Everything is done?
    if (_preparedNodes.isEmpty) {
      _resetMinimumProductionPriority();
      _stopTimeoutCheck();
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
  void _updatePriorityForNode(Node node) {
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
  // Graph

  String get _graph {
    {
      var result = '';
      result += 'digraph unix { ';

      for (final node in nodes) {
        for (final customer in node.customers) {
          final from = node.name;
          final to = customer.name;

          result += '"$from" -> "$to"; ';
        }
      }

      result += '}';

      return result;
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
}

// .............................................................................
Scm exampleScm({bool isTest = true}) => Scm(isTest: isTest);
