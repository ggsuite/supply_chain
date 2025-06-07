// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:supply_chain/supply_chain.dart';

/// The separation between nodes
const nodeSeparation = 0.25;

/// The separation between ranks
const rankSeparation = 0.25;

// .............................................................................
/// An item representing a node in the graph
class GraphNodeItem {
  /// Constructor
  GraphNodeItem({
    required this.node,
    required this.shownCustomers,
    this.isHighlighted = false,
  });

  /// The customers to be printed
  final List<GraphNodeItem> shownCustomers;

  /// The node represented by the item
  final Node<dynamic> node;

  /// Is the node highlighted
  final bool isHighlighted;

  @override
  String toString() => node.key;
}

// .............................................................................
/// An item representing a scope in the graph
class GraphScopeItem {
  /// Constructor
  GraphScopeItem({
    required this.scope,
    required this.nodeItems,
    required this.children,
    this.isHighlighted = false,
  }) {
    for (final node in nodeItems) {
      if (node.node.scope != scope) {
        throw ArgumentError('All nodes must be in the given scope.');
      }
    }
  }

  /// The scope represented by the node
  final Scope scope;

  /// The children to be printed
  final List<GraphScopeItem> children;

  /// The nodes to be shown in the scope
  final List<GraphNodeItem> nodeItems;

  /// Is the scope highlighted
  final bool isHighlighted;

  @override
  String toString() => scope.key;

  /// Find a node item in the graph
  GraphNodeItem? findNodeItem(Node<dynamic> node) {
    for (final nodeItem in nodeItems) {
      if (nodeItem.node == node) {
        return nodeItem;
      }
    }

    for (final child in children) {
      final result = child.findNodeItem(node);
      if (result != null) {
        return result;
      }
    }
    return null;
  }

  /// Find a scope item in the graph
  GraphScopeItem? findScopeItem(Scope scope) {
    if (this.scope == scope) {
      return this;
    }

    for (final child in children) {
      final result = child.findScopeItem(scope);
      if (result != null) {
        return result;
      }
    }
    return null;
  }
}

// #############################################################################
/// Creates a dot graph with certain configuration
class Graph {
  /// Constructor
  const Graph();

  // ...........................................................................
  /// Returns graph for a node that can be converted to the dot format later
  GraphScopeItem treeForNode({
    required Node<dynamic> node,
    int supplierDepth = 0,
    int customerDepth = 0,
    List<Node<dynamic>>? highlightedNodes,
    List<Scope>? highlightedScopes,
  }) {
    return _treeForNode(
      node: node,
      supplierDepth: supplierDepth,
      customerDepth: customerDepth,
      highlightedNodes: highlightedNodes,
      highlightedScopes: highlightedScopes,
    )!;
  }

  // ...........................................................................
  /// Returns a graph for a scope that can be converted to the dot format later
  GraphScopeItem treeForScope({
    required Scope scope,
    int childScopeDepth = 0,
    int parentScopeDepth = 0,
    List<Node<dynamic>>? highlightedNodes,
    List<Scope>? highlightedScopes,
  }) {
    return _treeForScope(
      scope: scope,
      childScopeDepth: childScopeDepth,
      parentScopeDepth: parentScopeDepth,
      highlightedNodes: highlightedNodes,
      highlightedScopes: highlightedScopes,
    )!;
  }

  // ...........................................................................
  /// Turn a graph into dot format
  static String dot({required GraphScopeItem graph}) {
    return GraphToDot(graph: graph).dot;
  }

  // ...........................................................................
  /// Turn a graph into mermaid format
  static String mermaid({required GraphScopeItem graph}) {
    return GraphToMermaid(graph: graph).mermaid;
  }

  // ...........................................................................
  /// Save the graph to a file
  ///
  /// The format can be dot, mmd, md, svg, png, pdf
  static Future<void> writeImageFile({
    required GraphScopeItem graph,
    required String path,
    double scale = 1.0,
    bool write2x = false,
  }) async {
    final format = path.split('.').last;

    // Write a dot file when form
    if (format == 'dot') {
      final file = File(path);
      await file.writeAsString(Graph.dot(graph: graph));
      return;
    } else {
      await GraphToMermaid(
        graph: graph,
      ).writeImageFile(path: path, scale: scale, write2x: write2x);
    }
  }

  // ######################
  // text
  // ######################

  // ...........................................................................
  GraphScopeItem? _treeForScope({
    required Scope scope,
    required int childScopeDepth,
    required int parentScopeDepth,
    List<Node<dynamic>>? highlightedNodes,
    List<Scope>? highlightedScopes,
  }) {
    // Get scopes to be shown
    final parentScopes = scope.deepParents(depth: parentScopeDepth);
    final childScopes = scope.deepChildren(depth: childScopeDepth);
    final scopesToBeShown = [...parentScopes, scope, ...childScopes];
    final scopesToBeShownWithChildren = [...scopesToBeShown];
    final scopesToBeShownEmpty = _scopesToBeShownEmpty(scopesToBeShown);
    scopesToBeShown.addAll(scopesToBeShownEmpty);

    // Show all nodes that are in the specified scopes
    final shownNodes = <Node<dynamic>>[];
    for (final scope in scopesToBeShownWithChildren) {
      shownNodes.addAll(scope.nodes);
    }

    // Order the scopes by depth
    final orderedScopes = scopesToBeShown.toList()
      ..sort((a, b) => a.depth.compareTo(b.depth));

    // Create the graph based on the scopes
    final graph = _graphFromScopes(
      shownScopes: orderedScopes,
      shownNodes: shownNodes,
      highlightedNodes: highlightedNodes,
      highlightedScopes: highlightedScopes,
    );

    return graph;
  }

  // ...........................................................................
  List<Scope> _scopesToBeShownEmpty(List<Scope> scopesToBeShown) {
    // We want to show child scopes of scopes to be shown as shells
    // without nodes and child scope.
    // Thus we are collecting all child scopes of the scopes to be shown
    // If a child scope is not part of scopesTeBeShown it is shown empty.
    final result = <Scope>[];
    for (final scope in scopesToBeShown) {
      for (final child in scope.children) {
        if (!scopesToBeShown.contains(child)) {
          result.add(child);
        }
      }
    }

    return result;
  }

  // ...........................................................................
  GraphScopeItem? _treeForNode({
    required Node<dynamic> node,
    required int supplierDepth,
    required int customerDepth,
    List<Node<dynamic>>? highlightedNodes,
    List<Scope>? highlightedScopes,
  }) {
    // Get all supplier nodes
    final supplierNodes = node.deepSuppliers(depth: supplierDepth);
    final customerNodes = node.deepCustomers(depth: customerDepth);

    // Get shown nodes
    final shownNodes = [node, ...supplierNodes, ...customerNodes];

    // Get a list of all scopes to be shown
    final scopesToBeShown = _scopesCoveredByNodes(shownNodes);

    // Order the scopes by depth
    final orderedScopes = scopesToBeShown.toList()
      ..sort((a, b) => a.depth.compareTo(b.depth));

    // Create the graph based on the scopes
    final graph = _graphFromScopes(
      shownScopes: orderedScopes,
      shownNodes: shownNodes,
      highlightedNodes: highlightedNodes,
      highlightedScopes: highlightedScopes,
    );

    return graph;
  }

  // ...........................................................................
  Set<Scope> _scopesCoveredByNodes(Iterable<Node<dynamic>> nodes) {
    // Get all scopes covered by the nodes
    final scopes = <Scope>{};
    for (final node in nodes) {
      scopes.add(node.scope);
    }

    // Get common parent scope
    final commonParent = _commonParent(scopes);
    scopes.add(commonParent);

    // Add all scope that are inbetween the common parent and the scopes
    for (final scope in [...scopes]) {
      var current = scope;
      while (current != commonParent) {
        scopes.add(current);
        current = current.parent!;
      }
    }

    return scopes;
  }

  // ...........................................................................
  Scope _commonParent(Iterable<Scope> scopes) =>
      scopes.reduce((a, b) => a.commonParent(b));

  // ...........................................................................
  GraphScopeItem _graphFromScopes({
    required List<Scope> shownScopes,
    required List<Node<dynamic>> shownNodes,
    List<Node<dynamic>>? highlightedNodes,
    List<Scope>? highlightedScopes,
  }) {
    // Iterate over all scopes beginning at the end
    // (the last scope is the most detailed one)

    final scope = shownScopes.first;
    final shownChildren = _shownChildren(
      scope,
      shownScopes,
      shownNodes,
      highlightedNodes,
      highlightedScopes,
    );

    final graphScopeItem = GraphScopeItem(
      scope: scope,
      children: shownChildren,
      isHighlighted: highlightedScopes?.contains(scope) ?? false,
      nodeItems: _shownNodesInScope(scope, shownNodes, highlightedNodes),
    );

    return graphScopeItem;
  }

  // ...........................................................................
  List<GraphScopeItem> _shownChildren(
    Scope scope,
    List<Scope> shownScopes,
    List<Node<dynamic>> shownNodes,
    List<Node<dynamic>>? highlightedNodes,
    List<Scope>? highlightedScopes,
  ) {
    final result = <GraphScopeItem>[];
    for (final child in scope.children) {
      if (shownScopes.contains(child)) {
        result.add(
          GraphScopeItem(
            scope: child,
            children: _shownChildren(
              child,
              shownScopes,
              shownNodes,
              highlightedNodes,
              highlightedScopes,
            ),
            isHighlighted: highlightedScopes?.contains(child) ?? false,
            nodeItems: _shownNodesInScope(child, shownNodes, highlightedNodes),
          ),
        );
      }
    }
    return result;
  }

  // ...........................................................................
  List<GraphNodeItem> _shownNodes(
    Iterable<Node<dynamic>> nodes,
    Iterable<Node<dynamic>>? allShownNodes,
  ) {
    final result = <GraphNodeItem>[];
    for (final node in nodes) {
      if (allShownNodes == null || allShownNodes.contains(node)) {
        final graphItem = GraphNodeItem(
          node: node,
          isHighlighted: false,
          shownCustomers: [],
        );
        result.add(graphItem);
      }
    }
    return result;
  }

  // ...........................................................................
  List<GraphNodeItem> _shownNodesInScope(
    Scope scope,
    List<Node<dynamic>> allShownNodes,
    List<Node<dynamic>>? highlightedNodes,
  ) {
    final nodes = allShownNodes.where((node) => node.scope == scope).toList();
    final result = <GraphNodeItem>[];
    for (final node in nodes) {
      result.add(
        GraphNodeItem(
          node: node,
          isHighlighted: highlightedNodes?.contains(node) ?? false,
          shownCustomers: _shownNodes(node.customers, allShownNodes),
        ),
      );
    }

    return result;
  }
}
