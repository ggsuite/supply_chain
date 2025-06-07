// @license
// Copyright (c) 2025 Dr. Gabriel Gatzsche
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';

/// Converts a graph to the Mermaid format.
class GraphToMermaid {
  /// Constructor
  GraphToMermaid({required this.graph, this.indent = 2})
      : _baseIndent = ' ' * indent;

  /// The graph to be converted
  final GraphScopeItem graph;

  /// The indentation
  final int indent;

  /// Turn a graph into Mermaid format
  String get mermaid {
    var header = 'flowchart TD\n';
    final nodes = _mermaidNodes(graph, indent: indent);
    final edges = _mermaidEdges(graph);
    final style = _style;
    return '$header$nodes\n$edges\n$style';
  }

  // ######################
  // Private
  // ######################

  // ...........................................................................
  // Nodes and clusters (subgraphs)
  String _mermaidNodes(GraphScopeItem scopeItem, {required int indent}) {
    var result = '';
    final scope = scopeItem.scope;
    final scopeId = '${scope.key}_${scope.id}';

    // Create a subgraph for this scope
    result += ' ' * indent + 'subgraph $scopeId["${scope.key}"]\n';

    // Write each node
    for (final nodeItem in scopeItem.nodeItems) {
      final node = nodeItem.node;
      final nodeId = _nodeId(node);
      final highlight = nodeItem.isHighlighted ? ':::highlight' : '';
      result += ' ' * (indent + 2) + '$nodeId["${node.key}"]$highlight\n';
    }

    // Write the child scopes
    for (final childScope in scopeItem.children) {
      result += _mermaidNodes(childScope, indent: indent + 2);
    }

    result += ' ' * indent + 'end\n';
    return result;
  }

  final String _baseIndent;

  // ...........................................................................
  String _mermaidEdges(
    GraphScopeItem scopeItem,
  ) {
    var result = '';

    // Write dependencies
    for (final nodeItem in scopeItem.nodeItems) {
      final node = nodeItem.node;

      for (final customer in nodeItem.shownCustomers) {
        final from = _nodeId(node);
        final to = _nodeId(customer.node);
        result += '$_baseIndent$from --> $to;\n';
      }
    }

    // Write the child scopes
    for (final childScopeItem in scopeItem.children) {
      result += _mermaidEdges(childScopeItem);
    }

    return result;
  }

  // ...........................................................................
  String get _style {
    return '  classDef highlight fill:#FFFFAA,stroke:#333;';
  }

  // ...........................................................................
  String _nodeId(Node<dynamic> node) => '${node.key}_${node.id}';
}
