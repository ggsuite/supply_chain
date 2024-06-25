// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';

/// A node that can be used as a insert node.
class Insert<T> extends Node<T> {
  /// Creates a new insert node based on [bluePrint] within [host]
  /// and inserts it into the insert chain at [index]
  Insert({
    required super.bluePrint,
    required this.host,
    Scope? scope,
    int? index,
  }) : super(scope: scope ?? host.scope) {
    _insertInsert(index);
    _prepareRemoval();
  }

  @override
  void dispose() {
    for (final d in _dispose.reversed) {
      d();
    }
    _dispose.clear();

    super.dispose();
  }

  /// Make sure this node is a insert node
  @override
  bool get isInsert => true;

  // ...........................................................................
  /// The node hosting this insert node
  final Node<T> host;

  /// From this node the insert node gets its input
  late Node<T> input;

  /// To this node the insert node sends its output
  late Node<T> output;

  // ...........................................................................
  /// Returns true if this insert is the last insert in the chain
  bool get isLastInsert => host.inserts.last == this;

  // ...........................................................................
  /// This override makes produce forwarding the insertInput's value to the
  /// produce function.
  // @override
  @override
  T get previousProduct => input.originalProduct;

  // ...........................................................................
  /// Creates an example insert node.
  static Insert<int> example({
    String key = 'insert',
    Produce<int>? produce,
    Node<int>? host,
    int? index,
  }) {
    host ??= Node.example();
    final bluePrint = NodeBluePrint.example(
      key: key,
      produce: produce,
    );
    final insert = bluePrint.instantiateAsInsert(
      host: host,
      scope: host.scope,
      index: index,
    );
    return insert;
  }

  // ######################
  // Private
  // ######################

  final List<void Function()> _dispose = [];

  void _insertInsert(int? index) {
    // Check index
    index ??= host.inserts.length;
    if (index < 0 || index > host.inserts.length) {
      throw ArgumentError('Insert index $index is out of range.');
    }

    // Get the previous and following insert
    final previousInsert =
        index == 0 ? null : host.inserts.elementAt(index - 1);

    final followingInsert =
        index >= host.inserts.length ? null : host.inserts.elementAt(index);

    // Connect previous and following insert to the new insert
    previousInsert?.output = this;
    followingInsert?.input = this;

    input = previousInsert ?? host;
    output = followingInsert ?? host;

    // Add insert to the list of inserts
    host.addInsert(this, index: index);

    // Nominate the insert
    scm.nominate(this);
  }

  void _removeInsertFromChain() {
    final inserts = host.inserts as List<Insert<T>>;
    final index = inserts.indexOf(this);

    final previousInsert = index > 0 ? inserts[index - 1] : null;
    final followingInsert =
        index < inserts.length - 1 ? inserts[index + 1] : null;

    previousInsert?.output = followingInsert ?? host;
    followingInsert?.input = previousInsert ?? host;

    // If this insert is the last insert
    if (this.isLastInsert) {
      // customers need to be nominated
      for (final customer in host.customers) {
        scm.nominate(customer);
      }

      // The product of the newly last insert needs to be written to the host
      host.insertResult = previousInsert?.originalProduct;
    }

    // If this insert is not the last insert, the following insert needs to be
    // nominated
    else {
      scm.nominate(output);
    }

    host.removeInsert(this);
  }

  void _prepareRemoval() {
    _dispose.add(_removeInsertFromChain);
  }
}
