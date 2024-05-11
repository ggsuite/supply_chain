// @license
// Copyright (c) 2019 - 2023 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';

/// Organizes a linear chain of workers
class AssemblyLine<T> {
  /// Constructor
  AssemblyLine({
    required this.input,
    required this.output,
  }) {
    assert(input != output);
  }

  // ...........................................................................
  /// Returns the works of the assembly line
  Iterable<Worker<T>> get workers => _workers;

  // ...........................................................................
  /// Add a worker to the assembly line
  void addWorker(Worker<T> worker) {
    // Worker is already added? Do nothing.
    if (_workers.lastOrNull == worker) {
      return;
    }

    // Worker exists earlier in chain? Throw an error.
    if (_workers.contains(worker)) {
      throw ArgumentError('Worker is already in the previous chain');
    }

    // Is first worker? Connect worker with input and output
    if (_workers.isEmpty) {
      input.addCustomer(worker);
      output.addSupplier(worker);
      input.removeCustomer(output);
      output.removeSupplier(input);
    }

    // Otherwise
    else {
      // Disconnect last worker from output
      output.removeSupplier(_workers.last);

      // Connect last worker with new worker
      _workers.last.addCustomer(worker);

      // Connect output with new last worker
      output.addSupplier(worker);
    }

    // Add worker to list of workers
    _workers.add(worker);
  }

  // ...........................................................................
  /// Remove a worker from the assembly line
  void removeWorker(Worker<T> worker) {
    // Worker already removed? Do nothing.
    final index = _workers.indexOf(worker);
    if (index < 0) {
      return;
    }

    // Worker is last remaining worker?
    // Connect input to output
    if (_workers.length == 1) {
      worker.removeSupplier(input);
      worker.removeCustomer(output);

      input.addCustomer(output);
      output.addSupplier(input);
    }

    // Worker is first worker?
    // Connect input to second worker?
    else if (worker == _workers.first) {
      final secondWorker = _workers[1];
      secondWorker.addSupplier(input);
      worker.removeSupplier(input);
      worker.removeCustomer(secondWorker);
    }

    // Worker is worker at the end of the chain?
    // Connect second last worker to output
    else if (worker == _workers.last) {
      final secondLastWorker = _workers[_workers.length - 2];
      secondLastWorker.addCustomer(output);
      worker.removeSupplier(secondLastWorker);
      worker.removeCustomer(output);
    }

    // Worker is inbetween?
    // Connect predecessor to successor
    else {
      final workerBefore = _workers[index - 1];
      final workerAfter = _workers[index + 1];
      workerBefore.addCustomer(workerAfter);
      worker.removeCustomer(workerAfter);
      worker.removeSupplier(workerBefore);
    }

    // Remove workers from array
    _workers.remove(worker);
  }

  // ...........................................................................
  /// The input node off the assembly line
  final Node<T> input;

  /// The output node off the assembly line
  final Node<T> output;
  final List<Worker<T>> _workers = [];
}

// #############################################################################
/// Example assembly line for test purposes
AssemblyLine<int> exampleAssemblyLine({
  Node<int>? input,
  Node<int>? output,
}) =>
    AssemblyLine<int>(
      input: input ?? exampleNode(),
      output: output ?? exampleNode(),
    );
