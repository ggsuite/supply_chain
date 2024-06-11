// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';

/// Maps a host node key to a node blueprint describing the plugin
typedef PluginMap = Map<String, NodeBluePrint<dynamic>>;

/// A scope plugin defines a list of node plugins that modify a scope.
class ScopePlugin {
  /// Constructor
  const ScopePlugin({required this.nodePlugins});

  /// Returns the node plugins
  final PluginMap nodePlugins;
}
