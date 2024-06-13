// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';

/// A node that can be used as a plugin node.
class PluginNode<T> extends Node<T> {
  /// Creates a new plugin node based on [bluePrint] within [host]
  /// and inserts it into the plugin chain at [index]
  PluginNode({
    required super.bluePrint,
    required this.host,
    Scope? scope,
    int? index,
  }) : super(scope: scope ?? host.scope) {
    _insertPlugin(index);
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

  /// Make sure this node is a plugin node
  @override
  bool get isPlugin => true;

  // ...........................................................................
  /// The node hosting this plugin node
  final Node<T> host;

  /// From this node the plugin node gets its input
  late Node<T> input;

  /// To this node the plugin node sends its output
  late Node<T> output;

  // ...........................................................................
  /// Returns true if this plugin is the last plugin in the chain
  bool get isLastPlugin => host.plugins.last == this;

  // ...........................................................................
  /// This override makes produce forwarding the pluginInput's value to the
  /// produce function.
  // @override
  @override
  T get previousProduct => input.originalProduct;

  // ...........................................................................
  /// Creates an example plugin node.
  static PluginNode<int> example({
    String key = 'plugin',
    Produce<int>? produce,
    Node<int>? host,
    int? index,
  }) {
    host ??= Node.example();
    final bluePrint = NodeBluePrint.example(
      key: key,
      produce: produce,
    );
    final pluginNode = bluePrint.instantiateAsPlugin(
      host: host,
      scope: host.scope,
      index: index,
    );
    return pluginNode;
  }

  // ######################
  // Private
  // ######################

  final List<void Function()> _dispose = [];

  void _insertPlugin(int? index) {
    // Check index
    index ??= host.plugins.length;
    if (index < 0 || index > host.plugins.length) {
      throw ArgumentError('Plugin index $index is out of range.');
    }

    // Get the previous and following plugin
    final previousPlugin =
        index == 0 ? null : host.plugins.elementAt(index - 1);

    final followingPlugin =
        index >= host.plugins.length ? null : host.plugins.elementAt(index);

    // Connect previous and following plugin to the new plugin
    previousPlugin?.output = this;
    followingPlugin?.input = this;

    input = previousPlugin ?? host;
    output = followingPlugin ?? host;

    // Add plugin to the list of plugins
    host.addPlugin(this, index: index);

    // Nominate the plugin
    scm.nominate(this);
  }

  void _removePluginFromChain() {
    final plugins = host.plugins as List<PluginNode<T>>;
    final index = plugins.indexOf(this);

    final previousPlugin = index > 0 ? plugins[index - 1] : null;
    final followingPlugin =
        index < plugins.length - 1 ? plugins[index + 1] : null;

    previousPlugin?.output = followingPlugin ?? host;
    followingPlugin?.input = previousPlugin ?? host;

    // If this plugin is the last plugin
    if (this.isLastPlugin) {
      // customers need to be nominated
      for (final customer in host.customers) {
        scm.nominate(customer);
      }

      // The product of the newly last plugin needs to be written to the host
      host.pluginResult = previousPlugin?.originalProduct;
    }

    // If this plugin is not the last plugin, the following plugin needs to be
    // nominated
    else {
      scm.nominate(output);
    }

    host.removePlugin(this);
  }

  void _prepareRemoval() {
    _dispose.add(_removePluginFromChain);
  }
}
