// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:io';

import 'package:supply_chain/supply_chain.dart';

/// Creates a html documentation of a given scope and its children
class Doc {
  /// Constructor
  Doc({required this.scope, required this.targetDirectory});

  /// Creates the documentation
  Future<void> create() async {
    scope.scm.initSuppliers();

    // Create directory
    final dir = Directory(targetDirectory);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    await dir.create(recursive: true);

    // Write content
    _writeHeader();
    await _writeScopes();
    _writeFooter();

    // Write index.html
    await File('$targetDirectory/index.html').writeAsString(lines.join('\n'));
  }

  /// The scope to be documented
  final Scope scope;

  /// The lines of the documentation
  final List<String> lines = [];

  /// The target directory the documentation is put to
  final String targetDirectory;

  // ######################
  // Private
  // ######################

  /// Write header
  void _writeHeader() {
    lines.add('<!DOCTYPE html>');
    lines.add('<meta charset="utf-8">');
    lines.add('<html>');
    lines.add('<head>');
    lines.add('<title>Dokumentation ${scope.key}</title>');
    lines.add('</head>');
    lines.add('<body>');
  }

  /// Write footer
  void _writeFooter() {
    lines.add('</body>');
    lines.add('</html>');
  }

  // ...........................................................................
  Future<void> _writeScopes() async {
    await _createDocForScope(scope);
  }

  // ...........................................................................
  Future<void> _createDocForScope(Scope scope) async {
    _scopeHeader(scope);
    await _nodes(scope);
    await _childScopes(scope);
  }

  // ...........................................................................
  void _scopeHeader(Scope scope) {
    lines.add('<h1>${scope.key}</h1>');
  }

  // ...........................................................................
  Future<void> _nodes(Scope scope) async {
    for (final node in scope.nodes) {
      await _node(node);
    }
  }

  // ...........................................................................
  Future<void> _childScopes(Scope scope) async {
    for (final child in scope.children) {
      await _createDocForScope(child);
    }
  }

  // ...........................................................................
  Future<void> _node(Node<dynamic> node) async {
    _nodeHeader(node);
    await _nodeGraph(node);
    _nodeSuppliers(node);
    _calculation(node);
  }

  // ...........................................................................
  void _nodeHeader(Node<dynamic> node) {
    lines.add('<h2>${node.key}</h2>');
  }

  // ...........................................................................
  void _nodeSuppliers(Node<dynamic> node) {
    if (node.suppliers.isEmpty) {
      return;
    }

    lines.add('<div>');
    lines.add('Ergibt sich aus: ');
    lines.add('<ul>');
    for (final supplier in node.suppliers) {
      final supplerAddress = node.bluePrint.suppliers
          .where((e) => supplier.matchesPath(e))
          .first;

      lines.add('<li><code>$supplerAddress</code></li>');
    }
    lines.add('</ul>');
    lines.add('</div>');
  }

  // ...........................................................................
  Future<void> _nodeGraph(Node<dynamic> node) async {
    if (Platform.environment.containsKey('GITHUB_ACTIONS')) {
      return;
    }

    // coverage:ignore-start
    final fileName = '${node.path.replaceAll('/', '.')}.png';
    final path = '$targetDirectory/$fileName';
    await node.writeImageFile(path, supplierDepth: -1, customerDepth: 0);

    lines.add('<img src="$fileName" alt="${node.key}"><br>');

    // coverage:ignore-end
  }

  // ...........................................................................
  void _calculation(Node<dynamic> node) {
    if (node.bluePrint.documentation.isEmpty) {
      return;
    }

    lines.add(node.bluePrint.documentation);
  }
}
