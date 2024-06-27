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
  }

  /// The blue print of the plugin
  final PluginBluePrint bluePrint;

  /// The scope this plugin is instantiated in
  final Scope scope;

  /// Returns an example instance of the plugin
  factory Plugin.example({
    String? key,
  }) {
    final scope = Scope.example();
    final bluePrint = PluginBluePrint.example(key: key);
    final plugin = Plugin(
      bluePrint: bluePrint,
      scope: scope,
    );
    return plugin;
  }

  // ######################
  // Private
  // ######################

  void _init() {
    _initScope();
  }

  void _initScope() {
    if (scope.plugin(bluePrint.key) != null) {
      throw ArgumentError('Another plugin with key ${bluePrint.key} is added.');
    }

    scope.addPlugin(this);
  }
}
