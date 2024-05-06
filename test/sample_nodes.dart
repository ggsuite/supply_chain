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
    initialProduct: 0,
    name: 'Supplier',
    scope: scope,
    produce: (p0) {
      // Produce
      p0.product++;

      // Announce new product
      p0.scm.hasNewProduct(p0);
    },
  );

  producer = Node<int>(
    initialProduct: 0,
    name: 'Producer',
    scope: scope,
    produce: (p0) {
      // Produce
      p0.product = (p0.suppliers.first.product as int) * 10;

      // Announce new product
      p0.scm.hasNewProduct(p0);
    },
  );

  customer = Node<int>(
    initialProduct: 0,
    name: 'Customer',
    scope: scope,
    produce: (p0) {
      // Produce
      p0.product = (p0.suppliers.first.product as int) + 1;

      // Announce new product
      p0.scm.hasNewProduct(p0);
    },
  );
}

// ...........................................................................
void initMusicExampleNodes() {
  // ......................
  // Key, Synth, Audio

  key = Node<int>(
    initialProduct: 0,
    name: 'Key',
    scope: scope,
    produce: (p0) {
      // Produce
      p0.product++;

      // Announce new product
      p0.scm.hasNewProduct(p0);
    },
  );

  synth = Node<int>(
    initialProduct: 0,
    name: 'Synth',
    scope: scope,
    produce: (p0) {
      // Produce
      p0.product = (p0.suppliers.first.product as int) * 10;

      // Announce new product
      p0.scm.hasNewProduct(p0);
    },
  );

  audio = Node<int>(
    initialProduct: 0,
    name: 'Audio',
    scope: scope,
    produce: (p0) {
      // Produce
      p0.product = (p0.suppliers.first.product as int) + 1;

      // Announce new product
      p0.scm.hasNewProduct(p0);
    },
  );

  screen = Node<int>(
    initialProduct: 0,
    name: 'Screen',
    scope: scope,
    produce: (p0) {
      // Produce
      p0.product = (p0.suppliers.first.product as int) * 100;

      // Announce new product
      p0.scm.hasNewProduct(p0);
    },
  );

  grid = Node<int>(
    initialProduct: 0,
    name: 'Grid',
    scope: scope,
    produce: (p0) {
      // Produce
      p0.product = (p0.suppliers.first.product as int) + 2;

      // Announce new product
      p0.scm.hasNewProduct(p0);
    },
  );
}

// ...........................................................................
void initTimeoutExampleNodes() {
  // ............................
  // SupplierA, SupplierB, Producer
  supplierA = Supplier<int>(
    initialProduct: 0,
    name: 'SupplierA',
    scope: scope,
    produce: (p0) {
      // Produce
      p0.product++;

      // Announce new product
      p0.scm.hasNewProduct(p0);
    },
  );

  supplierB = Supplier<int>(
    initialProduct: 0,
    name: 'SupplierB',
    scope: scope,
    produce: (p0) {
      // Produce
      p0.product += 10;

      // Don't announce product.
      // We will do it in test
    },
  );

  producer = Node<int>(
    initialProduct: 0,
    name: 'Producer',
    scope: scope,
    produce: (p0) {
      // Produce
      p0.product = (p0.suppliers.first.product as int) +
          (p0.suppliers.last.product as int);

      // Announce new product
      p0.scm.hasNewProduct(p0);
    },
  );
}

// ...........................................................................
void createSimpleChain() {
  producer.addSupplier(supplier);
  producer.addCustomer(customer);
}
