// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_is_github/gg_is_github.dart';
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
  String dot({
    required GraphScopeItem tree,
  }) {
    var result = '';
    result += 'digraph unix {\n';
    result += 'graph [ dpi = 75 ]; \n';
    result += 'graph [nodesep = $nodeSeparation; ranksep=$rankSeparation];\n';
    result += 'fontname="Helvetica,Arial,sans-serif"\n';
    result += 'node [fontname="Helvetica,Arial,sans-serif"]\n';
    result += 'edge [fontname="Helvetica,Arial,sans-serif"]\n';
    result += _dotNodes(tree);
    result += _dotEdges(tree);
    result += '}\n';
    return _indentDotGraph(result);
  }

  // ...........................................................................
  /// Save the graph to a file
  ///
  /// The format can be
  /// bmp canon cgimage cmap cmapx cmapx_np dot dot_json eps exr fig gd gd2 gif
  /// gv icns ico imap imap_np ismap jp2 jpe jpeg jpg json json0 kitty kittyz
  /// mp pct pdf pic pict plain plain-ext png pov ps ps2 psd sgi svg svgz tga
  /// tif tiff tk vrml vt vt-24bit wbmp webp xdot xdot1.2 xdot1.4 xdot_json
  Future<void> writeImageFile({
    required String dot,
    required String path,
  }) async {
    final format = path.split('.').last;

    final file = File(path);
    if (format == 'dot') {
      await file.writeAsString(dot);
      return;
    }
    // coverage:ignore-start
    else {
      if (!isGitHub) {
        // Write dot file to tmp
        final fileName = path.split('/').last;
        final tempDir = await Directory.systemTemp.createTemp();
        final tempPath = '${tempDir.path}/$fileName.dot';
        final tempFile = File(tempPath);
        tempFile.writeAsStringSync(dot);

        // Convert dot file to target format
        final process = await Process.run(
          'dot',
          ['-T$format', tempPath, '-o$path'],
        );
        await tempDir.delete(recursive: true);
        assert(process.exitCode == 0, process.stderr);
      }
    }
    // coverage:ignore-end
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

    // Show all nodes that are in the specified scopes
    final shownNodes = <Node<dynamic>>[];
    for (final scope in scopesToBeShown) {
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

  // ...........................................................................
  // Graph
  String _dotNodes(
    GraphScopeItem scopeItem,
  ) {
    {
      var result = '';
      final scope = scopeItem.scope;

      final scopeId = '${scope.key}_${scope.id}';

      // Create a cluster for this scope
      result += 'subgraph cluster_$scopeId {\n';
      result += 'label = "${scope.key}"; // scope\n';
      if (scopeItem.isHighlighted) {
        result += 'style = filled;\n';
        result += 'fillcolor = "#AAFFFF88";\n';
      }

      // Write an empty node, if nodeItems is empty
      if (scopeItem.nodeItems.isEmpty) {
        result +=
            'invisible [label = "", shape = point, style=invis]; // ${scope.key}\n';
      }

      // Write each node
      for (final nodeItem in scopeItem.nodeItems) {
        final node = nodeItem.node;
        final nodeId = _nodeId(node);
        result += '$nodeId [\n';
        result += '  label = "${node.key}"; // node\n';

        if (nodeItem.isHighlighted) {
          result += '  style = filled;\n';
          result += '  fillcolor = "#FFFFAA";\n';
        }

        result += '];\n';
      }

      // Write the child scopes
      for (final childScope in scopeItem.children) {
        result += _dotNodes(
          childScope,
        );
      }

      result += '\n}\n'; // cluster

      return result;
    }
  }

  // ...........................................................................
  String _dotEdges(
    GraphScopeItem scopeItem,
  ) {
    {
      var result = '';

      // Write dependencies
      for (final nodeItem in scopeItem.nodeItems) {
        final node = nodeItem.node;

        for (final customer in nodeItem.shownCustomers) {
          final from = _nodeId(node);
          final to = _nodeId(customer.node);
          result += '"$from" -> "$to";\n';
        }
      }

      // Write the child scopes
      for (final childScopeItem in scopeItem.children) {
        result += _dotEdges(childScopeItem);
      }

      return result;
    }
  }

  // ...........................................................................
  String _nodeId(Node<dynamic> node) => '${node.key}_${node.id}';

  // ...........................................................................
  String _indentDotGraph(String graph) {
    // Read the entire file content
    String content = graph;
    List<String> lines = content.split('\n');
    int indent = 0;
    List<String> indentedLines = [];
    const int spaces = 2;

    for (var line in lines) {
      // Adjust indentation
      if (line.contains('}')) {
        indent -= spaces;
      }

      // Apply current indentation and add line to results
      String indentedLine = ' ' * indent + line;
      indentedLines.add(indentedLine);

      if (line.contains('{')) {
        indent += spaces;
      }
    }

    // Join all indented lines into a single string
    String indentedContent = indentedLines.join('\n');

    return indentedContent;
  }
}
