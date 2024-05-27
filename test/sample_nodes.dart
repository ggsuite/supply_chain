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
    bluePrint: NodeBluePrint<int>(
      initialProduct: 0,
      key: 'supplier',
      produce: (components, previousProduct) => previousProduct + 1,
    ),
    scope: scope,
  );

  producer = Node<int>(
    bluePrint: NodeBluePrint<int>(
      initialProduct: 0,
      key: 'producer',
      produce: (List<dynamic> components, int previousProduct) {
        return (components.first as int) * 10;
      },
    ),
    scope: scope,
  );

  customer = Node<int>(
    bluePrint: NodeBluePrint<int>(
      initialProduct: 0,
      key: 'customer',
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
    bluePrint: NodeBluePrint<int>(
      initialProduct: 0,
      key: 'key',
      produce: (List<dynamic> components, int previousProduct) {
        return previousProduct + 1;
      },
    ),
    scope: scope,
  );

  synth = Node<int>(
    bluePrint: NodeBluePrint<int>(
      initialProduct: 0,
      key: 'synth',
      produce: (List<dynamic> components, int previousProduct) {
        // Produce
        return (components.first as int) * 10;
      },
    ),
    scope: scope,
  );

  audio = Node<int>(
    bluePrint: NodeBluePrint<int>(
      initialProduct: 0,
      key: 'audio',
      produce: (List<dynamic> components, int previousProduct) {
        // Produce
        return (components.first as int) + 1;
      },
    ),
    scope: scope,
  );

  screen = Node<int>(
    bluePrint: NodeBluePrint<int>(
      initialProduct: 0,
      key: 'screen',
      produce: (List<dynamic> components, int previousProduct) {
        // Produce
        return (components.first as int) * 100;
      },
    ),
    scope: scope,
  );

  grid = Node<int>(
    bluePrint: NodeBluePrint<int>(
      initialProduct: 0,
      key: 'grid',
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
          bluePrint: NodeBluePrint<int>(
            initialProduct: initialProduct,
            key: key,
            produce: produce,
          ),
        );

  @override
  void produce({bool announce = true}) {
    // Produce does nothing -> will cause a timeout
  }
}

// ...........................................................................
void initTimeoutExampleNodes() {
  // ............................
  // SupplierA, SupplierB, Producer
  supplierA = Node<int>(
    bluePrint: NodeBluePrint<int>(
      initialProduct: 0,
      key: 'supplierA',
      produce: (List<dynamic> components, int previousProduct) {
        // Produce
        return previousProduct + 1;
      },
    ),
    scope: scope,
  );

  supplierB = NodeTimingOut(
    initialProduct: 0,
    key: 'supplierB',
    scope: scope,
    produce: (List<dynamic> components, int previousProduct) {
      return previousProduct; // No change. No announcement.
    },
  );

  producer = Node<int>(
    bluePrint: NodeBluePrint<int>(
      initialProduct: 0,
      key: 'producer',
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
