// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';

/// Maps a host node address to a node blueprint describing the plugin
typedef PluginMap = Map<String, NodeBluePrint<dynamic>>;

/// A scope plugin defines a list of node plugins that modify a scope.
class ScopePlugin {
  /// Constructor
  const ScopePlugin({
    required this.key,
    this.overrides = const {},
  });

  /// Returns the node plugins
  final PluginMap overrides;

  /// The key of the plugin
  final String key;

  // ...........................................................................
  /// Disposes the plugin and removes it from the scope
  void dispose({required Scope scope}) {
    if (!scope.plugins.contains(this)) {
      throw ArgumentError('Plugin "$key" not found.');
    }

    // Get the plugin scope
    final pluginScope = scope.child(key)!;
    pluginScope.dispose();

    scope.scopePluginRemove(this);
  }

  // ...........................................................................
  /// Instantiates the plugin in the scope
  void instantiate({required Scope scope}) {
    if (scope.plugins.contains(this)) {
      throw ArgumentError('Plugin already added.');
    }

    final (hostNodes, nodePlugins) = _hostNodes(scope);

    // Create a scope for the plugin
    final pluginScopeBluePrint = ScopeBluePrint(key: key);
    final pluginScope = scope.addChild(pluginScopeBluePrint);

    // Add the plugins to each node
    for (var i = 0; i < hostNodes.length; i++) {
      final hostNode = hostNodes[i];
      final pluginBluePrint = nodePlugins[i];
      pluginBluePrint.instantiateAsPlugin(
        host: hostNode,
        scope: pluginScope,
      );
    }

    // Add the scope plugin to the list of scope plugins
    scope.scopePluginAdd(this);
  }

  // ...........................................................................
  /// Override this method in derived subclasses to build the plugin map
  PluginMap build() {
    return overrides;
  }

  // ...........................................................................
  (List<Node<dynamic>> hostNodes, List<NodeBluePrint<dynamic>> plugins)
      _hostNodes(
    Scope scope,
  ) {
    // Make sure all plugins have uinique keys
    final foundKeys = <String>{};

    final plugins = {...build()};

    for (final item in overrides.entries) {
      plugins[item.key] = item.value;
    }

    for (final nodePlugin in plugins.values) {
      if (foundKeys.contains(nodePlugin.key)) {
        throw ArgumentError(
          'Found multiple node plugins with key "${nodePlugin.key}":\n',
        );
      }
      foundKeys.add(nodePlugin.key);
    }

    // Find host nodes
    final hostAddresses = plugins.keys;
    final hostNodes = <Node<dynamic>>[];
    final nodePlugins = plugins.values.toList();
    final invalidAddresses = <String>[];
    for (final address in hostAddresses) {
      final node = scope.findNode<dynamic>(address);
      if (node != null) {
        hostNodes.add(node);
      } else {
        invalidAddresses.add(address);
      }
    }

    // Throw if not all host nodes are found
    if (invalidAddresses.isNotEmpty) {
      throw ArgumentError(
        'Host nodes not found: ${invalidAddresses.join(', ')}',
      );
    }

    return (hostNodes, nodePlugins);
  }

  // ...........................................................................
  /// Example innstance
  factory ScopePlugin.example({
    String key = 'scopePlugin',
  }) =>
      ScopePlugin(
        key: key,
        overrides: {
          'node0': const NodeBluePrint<int>(
            key: 'plugin0',
            initialProduct: 238,
          ),
        },
      );
}

// .............................................................................
/// An example plugin class
class ExampleScopePlugin extends ScopePlugin {
  /// Constructor
  const ExampleScopePlugin({
    super.key = 'exampleScopePlugin',
    super.overrides,
  });

  @override
  PluginMap build() {
    return {
      'node0': const NodeBluePrint<int>(key: 'plugin0', initialProduct: 822),
    };
  }
}
