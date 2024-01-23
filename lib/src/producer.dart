// @license
// Copyright (c) 2019 - 2023 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'node.dart';

/// Base class for all producer classes
///
/// Provides an interface for accessing an input and an output node.
/// In the most basic function the input = worker = output.
/// More complex prodcers can internally maintain multiple workers.
class Producer<T> {
  ///
  const Producer({
    required this.worker,
  })  : input = worker,
        output = worker;

  /// The input node. All suppliers are connected to the input node.
  final Node<T> input;

  /// The worker node.
  final Node<T> worker;

  /// The output node. All customers are connected to the output node.
  final Node<T> output;

  /// Add a supplier to the input node
  void addSupplier(Supplier<T> supplier) => input.addSupplier(supplier);

  /// Remove a supplier from the node
  void removeSupplier(Supplier<T> supplier) => input.removeSupplier(supplier);

  /// Add a customer to the output node
  void addCustomer(Customer<T> customer) => output.addCustomer(customer);

  /// Remove a customer from the output node
  void removeCustomer(Customer<T> customer) => output.removeCustomer(customer);
}

// #############################################################################
/// Creates an example producer for test purposes
Producer<int> exampleProducer({Node<int>? worker}) =>
    Producer(worker: worker ?? exampleNode());
