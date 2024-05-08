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
late SupplyChain scope;

// ...........................................................................
void initSupplierProducerCustomer() {
  // ............................
  // Supplier, Producer, Customer
  supplier = Supplier<int>(
    initialProduct: 0,
    key: 'Supplier',
    scope: scope,
    produce: (components, previousProduct) => previousProduct + 1,
  );

  producer = Node<int>(
    initialProduct: 0,
    key: 'Producer',
    scope: scope,
    produce: (components, previousProduct) {
      return (components.first as int) * 10;
    },
  );

  customer = Node<int>(
    initialProduct: 0,
    key: 'Customer',
    scope: scope,
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
    scope: scope,
    produce: (components, previousProduct) {
      return previousProduct + 1;
    },
  );

  synth = Node<int>(
    initialProduct: 0,
    key: 'Synth',
    scope: scope,
    produce: (components, previousProduct) {
      // Produce
      return (components.first as int) * 10;
    },
  );

  audio = Node<int>(
    initialProduct: 0,
    key: 'Audio',
    scope: scope,
    produce: (components, previousProduct) {
      // Produce
      return (components.first as int) + 1;
    },
  );

  screen = Node<int>(
    initialProduct: 0,
    key: 'Screen',
    scope: scope,
    produce: (components, previousProduct) {
      // Produce
      return (components.first as int) * 100;
    },
  );

  grid = Node<int>(
    initialProduct: 0,
    key: 'Grid',
    scope: scope,
    produce: (components, previousProduct) {
      // Produce
      return (components.first as int) + 2;
    },
  );
}

// ...........................................................................
void initTimeoutExampleNodes() {
  // ............................
  // SupplierA, SupplierB, Producer
  supplierA = Supplier<int>(
    initialProduct: 0,
    key: 'SupplierA',
    scope: scope,
    produce: (components, previousProduct) {
      // Produce
      return previousProduct + 1;
    },
  );

  supplierB = Supplier<int>(
    initialProduct: 0,
    key: 'SupplierB',
    scope: scope,
    produce: (components, previousProduct) {
      return previousProduct; // No change. No announcement.
    },
  );

  producer = Node<int>(
    initialProduct: 0,
    key: 'Producer',
    scope: scope,
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
