// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';

/// Realizes a customizer
class Customizer {
  /// Instante of a customizer blue print
  Customizer({
    required this.bluePrint,
    required this.scope,
  }) {
    _init();
  }

  /// Disposes the customizer
  void dispose() {
    for (var dispose in _dispose.reversed) {
      dispose();
    }
  }

  /// The blue print of the customizer
  final CustomizerBluePrint bluePrint;

  /// The scope this customizer is instantiated in
  final Scope scope;

  /// Returns an example instance of the customizer
  factory Customizer.example() {
    return CustomizerBluePrint.example;
  }

  /// The inserts of the customizer
  late final CustomizerInserts inserts;

  /// The node replacer of the customizer
  late final CustomizerNodeReplacer nodeReplacer;

  /// The node adder of the customizer
  late final CustomizerNodeAdder nodeAdder;

  /// The scope adder of the customizer
  late final CustomizerScopeAdder scopeAdder;

  // ######################
  // Private
  // ######################

  final List<Customizer> _children = [];

  final List<void Function()> _dispose = [];

  void _init() {
    _initScope();
    _initInserts();
    _initNodeReplacer();
    _initNodeAdder();
    _initScopeAdder();
    _initChildren(scope);
  }

  void _initScope() {
    if (scope.customizer(bluePrint.key) != null) {
      throw ArgumentError(
        'Another customizer with key ${bluePrint.key} is added.',
      );
    }

    scope.addCustomizer(this);

    _dispose.add(
      () => scope.removeCustomizer(this),
    );
  }

  void _initInserts() {
    inserts = CustomizerInserts(customizer: this);
    _dispose.add(inserts.dispose);
  }

  void _initNodeReplacer() {
    nodeReplacer = CustomizerNodeReplacer(customizer: this);
    _dispose.add(nodeReplacer.dispose);
  }

  void _initNodeAdder() {
    nodeAdder = CustomizerNodeAdder(customizer: this);
    _dispose.add(nodeAdder.dispose);
  }

  void _initScopeAdder() {
    scopeAdder = CustomizerScopeAdder(customizer: this);
    _dispose.add(scopeAdder.dispose);
  }

  void _initChildren(Scope scope) {
    // Init own children
    for (final child in bluePrint.customizers(hostScope: scope)) {
      _children.add(child.instantiate(scope: scope));
    }

    _dispose.add(
      () {
        for (var child in _children) {
          child.dispose();
        }
      },
    );

    for (final childScope in scope.children) {
      _initChildren(childScope);
    }
  }
}
