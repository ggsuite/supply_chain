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
late SupplyChain chain;

// ...........................................................................
void initSupplierProducerCustomer() {
  // ............................
  // Supplier, Producer, Customer
  supplier = Supplier<int>(
    initialProduct: 0,
    key: 'Supplier',
    chain: chain,
    produce: (components, previousProduct) => previousProduct + 1,
  );

  producer = Node<int>(
    initialProduct: 0,
    key: 'Producer',
    chain: chain,
    produce: (components, previousProduct) {
      return (components.first as int) * 10;
    },
  );

  customer = Node<int>(
    initialProduct: 0,
    key: 'Customer',
    chain: chain,
    produce: (components, previousProduct) {
      return (components.first as int) + 1;
    },
  );
}

// ...........................................................................
void initMusicExampleNodes() {
  // ......................
  // Key, Synth, Audio

  key = Node<int>(
    initialProduct: 0,
    key: 'Key',
    chain: chain,
    produce: (components, previousProduct) {
      return previousProduct + 1;
    },
  );

  synth = Node<int>(
    initialProduct: 0,
    key: 'Synth',
    chain: chain,
    produce: (components, previousProduct) {
      // Produce
      return (components.first as int) * 10;
    },
  );

  audio = Node<int>(
    initialProduct: 0,
    key: 'Audio',
    chain: chain,
    produce: (components, previousProduct) {
      // Produce
      return (components.first as int) + 1;
    },
  );

  screen = Node<int>(
    initialProduct: 0,
    key: 'Screen',
    chain: chain,
    produce: (components, previousProduct) {
      // Produce
      return (components.first as int) * 100;
    },
  );

  grid = Node<int>(
    initialProduct: 0,
    key: 'Grid',
    chain: chain,
    produce: (components, previousProduct) {
      // Produce
      return (components.first as int) + 2;
    },
  );
}

class NodeTimingOut extends Node<int> {
  /// Constructor
  NodeTimingOut({
    required super.initialProduct,
    required String super.key,
    required super.chain,
    required super.produce,
  });

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
    initialProduct: 0,
    key: 'SupplierA',
    chain: chain,
    produce: (components, previousProduct) {
      // Produce
      return previousProduct + 1;
    },
  );

  supplierB = NodeTimingOut(
    initialProduct: 0,
    key: 'SupplierB',
    chain: chain,
    produce: (components, previousProduct) {
      return previousProduct; // No change. No announcement.
    },
  );

  producer = Node<int>(
    initialProduct: 0,
    key: 'Producer',
    chain: chain,
    produce: (components, previousProduct) {
      // Produce
      return (components.first as int) + (components.last as int);
    },
  );
}

// ...........................................................................
void createSimpleChain() {
  producer.addSupplier(supplier);
  producer.addCustomer(customer);
}
