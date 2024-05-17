// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// ...........................................................................
// Simple chain nodes

import 'package:supply_chain/supply_chain.dart';

late Supplier<int> supplier;
late Node<int> producer;
late Customer<int> customer;

// Music example nodes
late Node<int> key;
late Customer<int> synth;
late Customer<int> audio;
late Customer<int> screen;
late Customer<int> grid;

// Timeout example nodes
late Supplier<int> supplierA;
late Supplier<int> supplierB;

late Scm scm;
late Scope scope;

// ...........................................................................
void initSupplierProducerCustomer() {
  // ............................
  // Supplier, Producer, Customer
  supplier = Supplier<int>(
    nodeConfig: NodeConfig<int>(
      initialProduct: 0,
      key: 'Supplier',
      produce: (components, previousProduct) => previousProduct + 1,
    ),
    scope: scope,
  );

  producer = Node<int>(
    nodeConfig: NodeConfig<int>(
      initialProduct: 0,
      key: 'Producer',
      produce: (List<dynamic> components, int previousProduct) {
        return (components.first as int) * 10;
      },
    ),
    scope: scope,
  );

  customer = Node<int>(
    nodeConfig: NodeConfig<int>(
      initialProduct: 0,
      key: 'Customer',
      produce: (List<dynamic> components, int previousProduct) {
        return (components.first as int) + 1;
      },
    ),
    scope: scope,
  );
}

// ...........................................................................
void initMusicExampleNodes() {
  // ......................
  // Key, Synth, Audio

  key = Node<int>(
    nodeConfig: NodeConfig<int>(
      initialProduct: 0,
      key: 'Key',
      produce: (List<dynamic> components, int previousProduct) {
        return previousProduct + 1;
      },
    ),
    scope: scope,
  );

  synth = Node<int>(
    nodeConfig: NodeConfig<int>(
      initialProduct: 0,
      key: 'Synth',
      produce: (List<dynamic> components, int previousProduct) {
        // Produce
        return (components.first as int) * 10;
      },
    ),
    scope: scope,
  );

  audio = Node<int>(
    nodeConfig: NodeConfig<int>(
      initialProduct: 0,
      key: 'Audio',
      produce: (List<dynamic> components, int previousProduct) {
        // Produce
        return (components.first as int) + 1;
      },
    ),
    scope: scope,
  );

  screen = Node<int>(
    nodeConfig: NodeConfig<int>(
      initialProduct: 0,
      key: 'Screen',
      produce: (List<dynamic> components, int previousProduct) {
        // Produce
        return (components.first as int) * 100;
      },
    ),
    scope: scope,
  );

  grid = Node<int>(
    nodeConfig: NodeConfig<int>(
      initialProduct: 0,
      key: 'Grid',
      produce: (List<dynamic> components, int previousProduct) {
        // Produce
        return (components.first as int) + 2;
      },
    ),
    scope: scope,
  );
}

class NodeTimingOut extends Node<int> {
  /// Constructor
  NodeTimingOut({
    required int initialProduct,
    required String key,
    required super.scope,
    required int Function(List<dynamic> components, int previousProduct)
        produce,
  }) : super(
          nodeConfig: NodeConfig<int>(
            initialProduct: initialProduct,
            key: key,
            produce: produce,
          ),
        );

  @override
  void produce() {
    // Produce does nothing -> will cause a timeout
  }
}

// ...........................................................................
void initTimeoutExampleNodes() {
  // ............................
  // SupplierA, SupplierB, Producer
  supplierA = Node<int>(
    nodeConfig: NodeConfig<int>(
      initialProduct: 0,
      key: 'SupplierA',
      produce: (List<dynamic> components, int previousProduct) {
        // Produce
        return previousProduct + 1;
      },
    ),
    scope: scope,
  );

  supplierB = NodeTimingOut(
    initialProduct: 0,
    key: 'SupplierB',
    scope: scope,
    produce: (List<dynamic> components, int previousProduct) {
      return previousProduct; // No change. No announcement.
    },
  );

  producer = Node<int>(
    nodeConfig: NodeConfig<int>(
      initialProduct: 0,
      key: 'Producer',
      produce: (List<dynamic> components, int previousProduct) {
        return (components.first as int) + (components.last as int);
      },
    ),
    scope: scope,
  );
}

// ...........................................................................
void createSimpleChain() {
  producer.addSupplier(supplier);
  producer.addCustomer(customer);
}
