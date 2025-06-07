// @license
// Copyright (c) 2025 Dr. Gabriel Gatzsche
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:supply_chain/supply_chain.dart';

/// Converts a graph to the DOT format.
class GraphToDot {
  /// Constructor
  GraphToDot({required this.tree, this.dpi = defaultDpi});

  /// The graph to be converted
  final GraphScopeItem tree;

  /// The dpi the graph is rendered
  final int dpi;

  /// The default dpi used for exporting the graph
  static const int defaultDpi = 72;

  /// Set this flag to true, to enable testing svg and png export.
  /// This is disabled by default because dot does generated different images
  /// on different platforms.
  static const testSvgAndPngExport = false;

  // ...........................................................................
  /// Turn a graph into dot format
  String get dot {
    var result = '';
    result += 'digraph unix {\n';
    result += 'graph [ dpi = $dpi ]; \n';
    result += 'graph [nodesep = $nodeSeparation; ranksep=$rankSeparation];\n';
    result += 'fontname="Arial"\n';
    result += 'node [fontname="Arial"]\n';
    result += 'edge [fontname="Arial"]\n';
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
  static Future<void> writeImageFile({
    required String dot,
    required String path,
    int dpi = GraphToDot.defaultDpi,
    bool write2x = false,
  }) async {
    final format = path.split('.').last;

    final file = File(path);
    if (format == 'dot') {
      await file.writeAsString(dot);
      return;
    }
    // coverage:ignore-start
    else {
      if (!Platform.environment.containsKey('GITHUB_ACTIONS')) {
        // Write dot file to tmp
        final fileName = path.split('/').last;

        final tempDir = await Directory.systemTemp.createTemp();
        final tempPath = '${tempDir.path}/$fileName.dot';
        final tempFile = File(tempPath);

        tempFile.writeAsStringSync(dot);

        // ..................................
        // Convert dot file to target format
        final process = await Process.run(
          'dot',
          ['-T$format', tempPath, '-o$path', '-Gdpi=$dpi'],
        );
        assert(process.exitCode == 0, process.stderr);

        // ..............
        // Write 2x image
        if (write2x && ['png', 'webp', 'jpg', 'jpeg'].contains(format)) {
          final path2x = path.replaceAll(RegExp('\\.$format\$'), '_2x.$format');

          final process = await Process.run(
            'dot',
            ['-T$format', tempPath, '-o$path2x', '-Gdpi=${dpi * 2}'],
          );
          assert(process.exitCode == 0, process.stderr);
        }

        // Delete the temporary directory
        await tempDir.delete(recursive: true);

        // Fix result and write it to the output file
        if (format == 'svg') {
          final svgFile = File(path);
          final svgContent = await svgFile.readAsString();
          final result = fixSvgViewBox(svgContent);
          await File(path).writeAsString(result);
        }
      }
    }
    // coverage:ignore-end
  }

  // ...........................................................................
  /// Fixes the viewBox of an SVG file. By default it does cut the content.
  static String fixSvgViewBox(String content) {
    // Regular expressions to find width and height
    RegExp widthRegex = RegExp(r'width="(\d+\.?\d*)pt"');
    RegExp heightRegex = RegExp(r'height="(\d+\.?\d*)pt"');

    // Find width and height matches
    Match? widthMatch = widthRegex.firstMatch(content);
    Match? heightMatch = heightRegex.firstMatch(content);

    if (widthMatch != null && heightMatch != null) {
      String width = widthMatch.group(1)!;
      String height = heightMatch.group(1)!;

      // Regular expression to replace the viewBox values
      RegExp viewBoxRegex =
          RegExp(r'viewBox="\d+\.?\d*\s+\d+\.?\d*\s+\d+\.?\d*\s+\d+\.?\d*"');
      String newViewBox = 'viewBox="0.00 0.00 $width $height"';

      // Replace the viewBox in the SVG content
      content = content.replaceFirst(viewBoxRegex, newViewBox);
    }

    return content;
  }

  // ######################
  // Private
  // ######################

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
            'invisible${_invisibleCounter++} [label = "", shape = point, style=invis]; // ${scope.key}\n';
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

  // ...........................................................................
  int _invisibleCounter = 0;

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
