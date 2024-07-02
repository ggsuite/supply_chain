// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';

/// Realizes a plugin
class Plugin {
  /// Instante of a plugin blue print
  Plugin({
    required this.bluePrint,
    required this.scope,
  }) {
    _init();
  }

  /// Disposes the plugin
  void dispose() {
    for (var dispose in _dispose.reversed) {
      dispose();
    }
  }

  /// The blue print of the plugin
  final PluginBluePrint bluePrint;

  /// The scope this plugin is instantiated in
  final Scope scope;

  /// Returns an example instance of the plugin
  factory Plugin.example() {
    return PluginBluePrint.example;
  }

  /// The inserts of the plugin
  late final PluginInserts inserts;

  /// The node replacer of the plugin
  late final PluginNodeReplacer nodeReplacer;

  /// The node adder of the plugin
  late final PluginNodeAdder nodeAdder;

  // ######################
  // Private
  // ######################

  final List<Plugin> _children = [];

  final List<void Function()> _dispose = [];

  void _init() {
    _initScope();
    _initInserts();
    _initNodeReplacer();
    _initNodeAdder();
    _initChildren(scope);
  }

  void _initScope() {
    if (scope.plugin(bluePrint.key) != null) {
      throw ArgumentError('Another plugin with key ${bluePrint.key} is added.');
    }

    scope.addPlugin(this);

    _dispose.add(
      () => scope.removePlugin(this),
    );
  }

  void _initInserts() {
    inserts = PluginInserts(plugin: this);
    _dispose.add(inserts.dispose);
  }

  void _initNodeReplacer() {
    nodeReplacer = PluginNodeReplacer(plugin: this);
    _dispose.add(nodeReplacer.dispose);
  }

  void _initNodeAdder() {
    nodeAdder = PluginNodeAdder(plugin: this);
    _dispose.add(nodeAdder.dispose);
  }

  void _initChildren(Scope scope) {
    // Init own children
    for (final child in bluePrint.plugins(hostScope: scope)) {
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
