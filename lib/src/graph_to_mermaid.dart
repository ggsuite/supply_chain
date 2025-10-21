// @license
// Copyright (c) 2025 Dr. Gabriel Gatzsche
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:supply_chain/supply_chain.dart';

/// The markdown export format
enum MarkdownFormat {
  /// Wraps mermaid code into ```
  gitHub,

  /// Wraps mermaid code into :::
  azure,
}

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

  /// Turn a graph into mermaid markdown
  String markdown({MarkdownFormat markdownFormat = MarkdownFormat.gitHub}) {
    final d = switch (markdownFormat) {
      MarkdownFormat.azure => ':::',
      MarkdownFormat.gitHub => '```',
    };

    // :::mermaid ...code ... :::
    final result = ['${d}mermaid', mermaid, d].join('\n');
    return result;
  }

  /// Save the graph as an image file
  ///
  /// The format can be dot, mmd, md, svg, png, pdf
  Future<void> writeImageFile({
    required String path,
    double scale = 1.0,
    bool write2x = false,
    MarkdownFormat markdownFormat = MarkdownFormat.gitHub,
  }) async {
    // Get the format
    final format = path.split('.').last;
    final mm = mermaid;

    // Write mmd files directly
    final file = File(path);
    if (format == 'mmd') {
      await file.writeAsString(mm);
      return;
    }
    // Write markdown file
    else if (format == 'md') {
      final result = markdown(markdownFormat: markdownFormat);
      await file.writeAsString(result);
    }
    // coverage:ignore-start
    else {
      if (!Platform.environment.containsKey('GITHUB_ACTIONS') &&
          !Platform.environment.containsKey('TF_BUILD')) {
        // Check if mmdc is installed
        var error = 0;
        try {
          final mmdcProcess = await Process.run('mmdc', ['--version']);
          error = mmdcProcess.exitCode;
        } catch (e) {
          error = 1;
        }

        if (error != 0) {
          throw Exception(
            [
              'Mermaid CLI (mmdc) is not installed. ',
              'Please install it via npm:',
              'npm install -g @mermaid-js/mermaid-cli',
            ].join('\n'),
          );
        }

        // Write mermaid file to tmp
        final fileName = path.split('/').last;

        final tempDir = await Directory.systemTemp.createTemp();
        final tempPath = '${tempDir.path}/$fileName.mmd';
        final tempFile = File(tempPath);

        await tempFile.writeAsString(mm);

        // ..................................
        // Convert dot file to target format
        final process = await Process.run('mmdc', [
          '-i$tempPath',
          '-o$path',
          '-s$scale',
        ]);
        assert(process.exitCode == 0, process.stderr);

        // ..............
        // Write 2x image
        if (write2x && ['png', 'webp', 'jpg', 'jpeg'].contains(format)) {
          final path2x = path.replaceAll(RegExp('\\.$format\$'), '_2x.$format');

          final process = await Process.run('dot', [
            '-T$format',
            tempPath,
            '-o$path2x',
            '-s$scale',
          ]);
          assert(process.exitCode == 0, process.stderr);
        }

        // Delete the temporary directory
        await tempDir.delete(recursive: true);
      }
    }
    // coverage:ignore-end
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
  String _mermaidEdges(GraphScopeItem scopeItem) {
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
