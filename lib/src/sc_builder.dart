// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:math';

import 'package:supply_chain/supply_chain.dart';

/// Realizes a builder
class ScBuilder {
  /// Instante of a builder blue print
  ScBuilder({
    required this.bluePrint,
    required this.scope,
  }) {
    _init();
    applyToScope(scope);
  }

  /// Disposes the builder
  void dispose() {
    for (var dispose in _dispose.reversed) {
      dispose();
    }
  }

  /// Applies the builder to this scope and all its children
  void applyToScope(Scope scope, {bool applyToChildren = true}) {
    inserts.applyToScope(scope);
    nodeReplacer.applyToScope(scope);
    nodeAdder.applyToScope(scope);
    scopeAdder.applyToScope(scope);
    _applyChildBuilders(scope);

    if (applyToChildren) {
      _applyBuildersToChildScopes(scope);
    }
  }

  /// Applies the builder to this node
  void applyToNode(Node<dynamic> node) {
    inserts.applyToNode(node);
    nodeReplacer.applyToNode(node);
  }

  /// The blue print of the builder
  final ScBuilderBluePrint bluePrint;

  /// The scope this builder is instantiated in
  final Scope scope;

  /// Returns an example instance of the builder
  factory ScBuilder.example() {
    return ScBuilderBluePrint.example;
  }

  /// The inserts of the builder
  late final ScBuilderInserts inserts;

  /// The node replacer of the builder
  late final ScBuilderNodeReplacer nodeReplacer;

  /// The node adder of the builder
  late final ScBuilderNodeAdder nodeAdder;

  /// The scope adder of the builder
  late final ScBuilderScopeAdder scopeAdder;

  /// This scope is used to perform checks
  static final testScope =
      Scope.example(key: 'scBuilderTestScope${Random().nextInt(1000)}');

  // ######################
  // Private
  // ######################

  final List<ScBuilder> _children = [];

  final List<void Function()> _dispose = [];

  void _init() {
    _initScope();
    _initInserts();
    _initNodeReplacer();
    _initNodeAdder();
    _initScopeAdder();
    _updateOnSupplierChange();
  }

  void _initScope() {
    if (scope.builder(bluePrint.key) != null) {
      return;
      // throw ArgumentError(
      //   'Another builder with key ${bluePrint.key} is added.',
      // );
    }

    scope.addScBuilder(this);

    _dispose.add(
      () => scope.removeScBuilder(this),
    );
  }

  void _initInserts() {
    inserts = ScBuilderInserts(builder: this);
    _dispose.add(inserts.dispose);
  }

  void _initNodeReplacer() {
    nodeReplacer = ScBuilderNodeReplacer(builder: this);
    _dispose.add(nodeReplacer.dispose);
  }

  void _initNodeAdder() {
    nodeAdder = ScBuilderNodeAdder(builder: this);
    _dispose.add(nodeAdder.dispose);
  }

  void _initScopeAdder() {
    scopeAdder = ScBuilderScopeAdder(builder: this);
    _dispose.add(scopeAdder.dispose);
  }

  void _applyChildBuilders(Scope scope) {
    for (final child in bluePrint.children(hostScope: scope)) {
      _children.add(child.instantiate(scope: scope));
    }

    _dispose.add(
      () {
        for (var child in _children) {
          child.dispose();
        }
      },
    );
  }

  void _applyBuildersToChildScopes(Scope scope) {
    _applyChildBuilders(scope);

    if (!bluePrint.shouldProcessChildrenOf(scope)) {
      return;
    }

    for (final childScope in scope.children) {
      _applyBuildersToChildScopes(childScope);
    }
  }

  // ...........................................................................
  void _updateOnSupplierChange() {
    // No suppliers? Do nothing.
    if (bluePrint.needsUpdateSuppliers.isEmpty) {
      return;
    }

    // Get the builders meta scope
    final buildersMetaScope = scope.metaScopeFindOrCreate('builders');

    // Create a node blue print listening to changes on the supplier
    final needsUpdate = NodeBluePrint<void>(
      key: '${bluePrint.key}NeedsUpdate',
      suppliers: bluePrint.needsUpdateSuppliers,
      initialProduct: null,
      produce: (components, previousProduct) => bluePrint.needsUpdate(
        hostScope: scope,
        components: components,
      ),
    );

    // Instantiate the blue print within host scospe
    final onChangeNode = needsUpdate.instantiate(scope: buildersMetaScope);

    _dispose.add(
      () => onChangeNode.dispose(),
    );
  }
}
