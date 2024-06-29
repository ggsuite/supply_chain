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
    scope.removePlugin(this);
    inserts.dispose();
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
  late final Inserts inserts;

  // ######################
  // Private
  // ######################

  void _init() {
    _initScope();
    _initInserts();
  }

  void _initScope() {
    if (scope.plugin(bluePrint.key) != null) {
      throw ArgumentError('Another plugin with key ${bluePrint.key} is added.');
    }

    scope.addPlugin(this);
  }

  void _initInserts() {
    inserts = Inserts(plugin: this);
  }
}
