// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:gg_is_github/gg_is_github.dart';
import 'package:supply_chain/supply_chain.dart';

/// Creates a dot graph with certain configuration
class Graph {
  /// Constructor
  const Graph();

  /// Returns a graph in dot format for the given scope
  ///
  /// Prints all nodes of the scope.
  /// Prints all suppliers of the nodes with [supplierDepth] levels.
  /// Prints all customers of the nodes with [customerDepth] levels.
  String fromNode(
    Node<dynamic> node, {
    int childScopeDepth = 1,
    int parentScopeDepth = 1,
    int supplierDepth = 1,
    int customerDepth = 1,
  }) {
    return _fromScope(
      node.scope,
      onlyNode: node,
      childScopeDepth: childScopeDepth,
      parentScopeDepth: parentScopeDepth,
      supplierDepth: supplierDepth,
      customerDepth: customerDepth,
      highlightedNode: node,
      highlightedScope: node.scope,
    );
  }

  /// Returns a graph in dot format for the given scope
  ///
  /// Prints all nodes of the scope.
  /// Prints all suppliers of the nodes with [supplierDepth] levels.
  /// Prints all customers of the nodes with [customerDepth] levels.
  String fromScope(
    Scope scope, {
    int childScopeDepth = 1,
    int parentScopeDepth = 1,
    int supplierDepth = 1,
    int customerDepth = 1,
    bool showDependentNodesOnly = true,
  }) {
    return _fromScope(
      scope,
      onlyNode: null,
      childScopeDepth: childScopeDepth,
      parentScopeDepth: parentScopeDepth,
      supplierDepth: supplierDepth,
      customerDepth: customerDepth,
      highlightedScope: scope,
      showDependentNodesOnly: showDependentNodesOnly,
    );
  }

  // ...........................................................................
  String _fromScope(
    Scope scope, {
    Node<dynamic>? onlyNode,
    int childScopeDepth = 1,
    int parentScopeDepth = 1,
    int supplierDepth = 1,
    int customerDepth = 1,
    bool showDependentNodesOnly = true,
    Node<dynamic>? highlightedNode,
    Scope? highlightedScope,
  }) {
    // Collect all affected nodes
    final nodesToBeShown = showDependentNodesOnly
        ? null
        : onlyNode != null
            ? [onlyNode]
            : <Node<dynamic>>[...scope.nodes];

    if (nodesToBeShown != null) {
      final nodesCopy = [...nodesToBeShown];
      for (final node in nodesCopy) {
        nodesToBeShown.addAll(node.deepCustomers(depth: customerDepth));
        nodesToBeShown.addAll(node.deepSuppliers(depth: supplierDepth));
      }
    }

    // Collect all affected scopes
    final scopesToBeShown = <Scope>[
      scope,
      ...scope.deepParents(depth: parentScopeDepth),
      ...scope.deepChildren(depth: childScopeDepth),
    ];

    // Get the common root of all scopes
    final commonParent = scopesToBeShown.reduce((a, b) => a.commonParent(b));

    // Get the intermediate scopes
    for (final node in nodesToBeShown ?? <Node<dynamic>>[]) {
      Scope? scope = node.scope;
      do {
        if (!scopesToBeShown.contains(scope)) {
          scopesToBeShown.add(scope!);
        }
        scope = scope?.parent;
      } while (scope != null && scope != commonParent);
    }

    var result = '';
    result += 'digraph unix {\n';
    result += 'graph [nodesep = 0.25; ranksep=1];\n';
    result += 'fontname="Helvetica,Arial,sans-serif"\n';
    result += 'node [fontname="Helvetica,Arial,sans-serif"]\n';
    result += 'edge [fontname="Helvetica,Arial,sans-serif"]\n';
    result += _graphNodes(
      commonParent,
      nodesToBeShown?.toList(),
      scopesToBeShown.toList(),
      highlightedScope: highlightedScope,
      highlightedNode: highlightedNode,
    );
    result += _graphEdges(
      commonParent,
      nodesToBeShown?.toList(),
      scopesToBeShown.toList(),
    );
    result += '}\n';
    return result;
  }

  /// Save the graph to a file
  ///
  /// The format can be
  /// bmp canon cgimage cmap cmapx cmapx_np dot dot_json eps exr fig gd gd2 gif
  /// gv icns ico imap imap_np ismap jp2 jpe jpeg jpg json json0 kitty kittyz
  /// mp pct pdf pic pict plain plain-ext png pov ps ps2 psd sgi svg svgz tga
  /// tif tiff tk vrml vt vt-24bit wbmp webp xdot xdot1.2 xdot1.4 xdot_json
  Future<void> writeScopeToFile(
    Scope scope,
    String path, {
    int childScopeDepth = 0,
    int parentScopeDepth = 1,
    int supplierDepth = 1,
    int customerDepth = 0,
    bool highLightScope = false,
    bool showDependentNodesOnly = false,
  }) async {
    await _writeScopeToFile(
      scope,
      path,
      childScopeDepth: childScopeDepth,
      parentScopeDepth: parentScopeDepth,
      supplierDepth: supplierDepth,
      customerDepth: customerDepth,
      highLightNode: false,
      highLightScope: highLightScope,
      showDependentNodesOnly: showDependentNodesOnly,
    );
  }

  /// Save the graph to a file
  ///
  /// The format can be
  /// bmp canon cgimage cmap cmapx cmapx_np dot dot_json eps exr fig gd gd2 gif
  /// gv icns ico imap imap_np ismap jp2 jpe jpeg jpg json json0 kitty kittyz
  /// mp pct pdf pic pict plain plain-ext png pov ps ps2 psd sgi svg svgz tga
  /// tif tiff tk vrml vt vt-24bit wbmp webp xdot xdot1.2 xdot1.4 xdot_json
  Future<void> writeNodeToFile(
    Node<dynamic> node,
    String path, {
    int childScopeDepth = 0,
    int parentScopeDepth = 1,
    int supplierDepth = 1,
    int customerDepth = 0,
    bool highLightNode = false,
  }) async {
    await _writeScopeToFile(
      node.scope,
      path,
      onlyNode: node,
      childScopeDepth: childScopeDepth,
      parentScopeDepth: parentScopeDepth,
      supplierDepth: supplierDepth,
      customerDepth: customerDepth,
      highLightNode: highLightNode,
    );
  }

  // ...........................................................................
  Future<void> _writeScopeToFile(
    Scope scope,
    String path, {
    Node<dynamic>? onlyNode,
    int childScopeDepth = 0,
    int parentScopeDepth = 1,
    int supplierDepth = 1,
    int customerDepth = 0,
    bool highLightScope = false,
    bool highLightNode = false,
    bool showDependentNodesOnly = false,
  }) async {
    final format = path.split('.').last;

    final content = _fromScope(
      scope,
      childScopeDepth: childScopeDepth,
      parentScopeDepth: parentScopeDepth,
      supplierDepth: supplierDepth,
      customerDepth: customerDepth,
      onlyNode: onlyNode,
      highlightedNode: highLightNode ? onlyNode : null,
      highlightedScope: highLightScope ? scope : null,
      showDependentNodesOnly: showDependentNodesOnly,
    );

    final formattedContent = _indentDotGraph(content);

    final file = File(path);
    if (format == 'dot') {
      await file.writeAsString(formattedContent);
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
        tempFile.writeAsStringSync(content);

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
  // Graph
  String _graphNodes(
    Scope scope,
    List<Node<dynamic>>? nodesToBeShown,
    List<Scope>? scopesToBeShown, {
    Scope? highlightedScope,
    Node<dynamic>? highlightedNode,
  }) {
    {
      var result = '';

      final scopeId = '${scope.key}_${scope.id}';

      // Create a cluster for this scope
      result += 'subgraph cluster_$scopeId {\n';
      result += 'label = "${scope.key}";\n';
      if (scope == highlightedScope) {
        result += 'style = filled;\n';
        result += 'fillcolor = "#AAFFFF88";\n';
      }

      // Estimate the relevant child scopes
      final relevantChildScopes = scopesToBeShown == null
          ? scope.children // coverage:ignore-line
          : scope.children
              .where(
                (element) => scopesToBeShown.contains(element),
              )
              .toList();

      // Remove the relevant child scopes from the list
      if (scopesToBeShown != null) {
        for (final node in relevantChildScopes) {
          scopesToBeShown.remove(node);
        }
      }

      for (final childScope in relevantChildScopes) {
        result += _graphNodes(
          childScope,
          nodesToBeShown,
          scopesToBeShown,
          highlightedScope: highlightedScope,
          highlightedNode: highlightedNode,
        );
      }

      // Estimate relevant nodes
      final relevantNodes = nodesToBeShown == null
          ? scope.nodes
          : scope.nodes
              .where(
                (element) => nodesToBeShown.contains(element),
              )
              .toList();

      // Remove the relevant nodes from the list
      if (nodesToBeShown != null) {
        for (final node in relevantNodes) {
          nodesToBeShown.remove(node);
        }
      }

      // Write each node
      for (final node in relevantNodes) {
        final nodeId = _nodeId(node);
        result += '$nodeId [\n';
        result += '  label="${node.key}"\n';

        if (node == highlightedNode) {
          result += '  style = filled;\n';
          result += '  fillcolor = "#FFFFAA";\n';
        }

        result += '];\n';
      }

      result += '\n}\n'; // cluster

      return result;
    }
  }

  String _graphEdges(
    Scope scope,
    List<Node<dynamic>>? nodesToBeShown,
    List<Scope>? scopesToBeShown,
  ) {
    {
      var result = '';

      // ..................
      // Write dependencies
      for (final node in scope.nodes) {
        if (nodesToBeShown != null && !nodesToBeShown.contains(node)) {
          continue;
        }

        for (final customer in node.customers) {
          if (nodesToBeShown != null && !nodesToBeShown.contains(customer)) {
            continue;
          }

          final from = _nodeId(node);
          final to = _nodeId(customer);

          result += '"$from" -> "$to";\n';
        }
      }

      // ..................................
      // Estimate the relevant child scopes
      final relevantChildScopes = scopesToBeShown == null
          ? scope.children // coverage:ignore-line
          : scope.children
              .where(
                (element) => scopesToBeShown.contains(element),
              )
              .toList();

      // Remove the relevant child scopes from the list
      if (scopesToBeShown != null) {
        for (final scope in relevantChildScopes) {
          scopesToBeShown.remove(scope);
        }
      }

      // Write the child scopes
      for (final childScope in relevantChildScopes) {
        result += _graphEdges(childScope, nodesToBeShown, scopesToBeShown);
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

    for (var line in lines) {
      // Adjust indentation
      if (line.contains('}')) {
        indent -= 4;
      }

      // Apply current indentation and add line to results
      String indentedLine = ' ' * indent + line.trim();
      indentedLines.add(indentedLine);

      if (line.contains('{')) {
        indent += 4;
      }
    }

    // Join all indented lines into a single string
    String indentedContent = indentedLines.join('\n');

    return indentedContent;
  }
}
