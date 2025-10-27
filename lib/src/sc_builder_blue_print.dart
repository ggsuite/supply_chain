// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';

/// A builder changes various aspects of a scope and its children
class ScBuilderBluePrint {
  // ...........................................................................
  ///  Creates a builder purely from constructor
  const ScBuilderBluePrint({
    required this.key,
    this.needsUpdateSuppliers = const [],
    List<ScopeBluePrint> Function({required Scope hostScope})? addScopes,
    bool Function(Scope scope)? shouldProcessChildren,
    bool Function(Scope scope)? shouldProcessScope,
    ScopeBluePrint Function({
      required Scope hostScope,
      required ScopeBluePrint scopeToBeReplaced,
    })?
    replaceScope,
    List<NodeBluePrint<dynamic>>? Function({required Scope hostScope})?
    addNodes,
    NodeBluePrint<dynamic>? Function({
      required Scope hostScope,
      required Node<dynamic> nodeToBeReplaced,
    })?
    replaceNode,
    List<NodeBluePrint<dynamic>> Function({required Node<dynamic> hostNode})?
    inserts,
    void Function({
      required Scope hostScope,
      required List<dynamic> components,
    })?
    needsUpdate,
    List<ScBuilderBluePrint> Function({required Scope hostScope})? children,
  }) : _addScopes = addScopes,
       _replaceScope = replaceScope,
       _addNodes = addNodes,
       _replaceNode = replaceNode,
       _inserts = inserts,
       _needsUpdate = needsUpdate,
       _children = children,
       _shouldProcessChildren = shouldProcessChildren,
       _shouldProcessScope = shouldProcessScope;

  /// Instantiates this builder and it's children within the given hostScope
  ///
  /// - [hostScope]: The scope this builder will be instantiated in
  /// - The callbacks below will be applied to the hostScope and all its
  ///   children
  ScBuilder instantiate({required Scope scope, ScBuilder? parent}) {
    return ScBuilder(bluePrint: this, scope: scope, parent: parent);
  }

  // ...........................................................................
  /// Override this method to react to the instantiation of the builder
  void onInstantiate({required Scope hostScope}) {}

  // ...........................................................................
  /// Determines whether the builder should process a scope's children
  ///
  /// This method should be overridden to define which scopes should allow
  /// their children to be processed by the builder.
  ///
  /// If the method returns `false` for a given [scope], the builder will skip
  /// processing its children. If it returns `true`, the children will be
  /// processed.
  ///
  /// By default, the method checks a delegate function
  /// `shouldProcessChildren`
  /// (if provided), and returns `true` if the function is not defined.
  ///
  /// - Parameter [scope]: The scope for which the decision to process
  ///   children is made.
  /// - Returns: A boolean indicating whether the children of the given scope
  ///   should be processed.
  bool shouldProcessChildren(Scope scope) {
    return _shouldProcessChildren?.call(scope) ??
        (throw UnimplementedError(
          'Please either specify shouldProcessChildren constructor '
          'parameter '
          'or override shouldProcessChildren method in your class derived '
          'from ScBuilderBluePrint.',
        ));
  }

  // ...........................................................................
  /// Determines whether the builder should process a scope
  ///
  /// This method should be overridden to define which scopes should allow
  /// their children to be processed by the builder.
  ///
  /// If the method returns `false` for a given [scope], the builder will skip
  /// processing its children. If it returns `true`, the children will be
  /// processed.
  ///
  /// By default, the method checks a delegate function
  /// `shouldProcessScope`
  /// (if provided), and returns `true` if the function is not defined.
  ///
  /// - Parameter [scope]: The scope for which the decision to process
  ///   children is made.
  /// - Returns: A boolean indicating whether the children of the given scope
  ///   should be processed.
  bool shouldProcessScope(Scope scope) {
    return _shouldProcessScope?.call(scope) ??
        (throw UnimplementedError(
          'Please either specify shouldProcessScope constructor '
          'parameter '
          'or override shouldProcessScope method in your class derived '
          'from ScBuilderBluePrint.',
        ));
  }

  // ...........................................................................
  // Modify scopes

  /// Override this method to add scopes to the given host scope
  ///
  /// - [hostScope]: The host scope the returned scopes will be added to
  /// - Returns: A list of scopes to be added to the host scope
  List<ScopeBluePrint> addScopes({required Scope hostScope}) {
    return _addScopes?.call(hostScope: hostScope) ?? [];
  }

  /// Override this method to replace scopes in the given host scope
  ///
  /// - [hostScope]: The host scope the replaced scope is coming from
  /// - [scopeToBeReplaced]: The original version of the scope to be replaced
  /// - returns: The replaced version of [scopeToBeReplaced]
  ScopeBluePrint replaceScope({
    required Scope hostScope,
    required ScopeBluePrint scopeToBeReplaced,
  }) {
    return _replaceScope?.call(
          hostScope: hostScope,
          scopeToBeReplaced: scopeToBeReplaced,
        ) ??
        scopeToBeReplaced;
  }

  // ...........................................................................
  // Modify nodes

  /// Override this method to add nodes to a given host scope
  ///
  /// - [hostScope]: The host scope the returned nodes will be added to
  /// - Returns: A list of nodes to be added to the host scope
  List<NodeBluePrint<dynamic>> addNodes({required Scope hostScope}) {
    return _addNodes?.call(hostScope: hostScope) ?? [];
  }

  /// Override this method to replace a scope in a given host scope
  ///
  /// - [hostScope]: The host scope the replaced node is coming from
  /// - [nodeToBeReplaced]: The original version of the node to be replaced
  /// - Returns: The replaced version of [nodeToBeReplaced]
  NodeBluePrint<dynamic> replaceNode({
    required Scope hostScope,
    required Node<dynamic> nodeToBeReplaced,
  }) {
    return _replaceNode?.call(
          hostScope: hostScope,
          nodeToBeReplaced: nodeToBeReplaced,
        ) ??
        nodeToBeReplaced.bluePrint;
  }

  // ...........................................................................
  // Inserts

  /// Override this method to add inserts into a given node
  ///
  /// - [hostNode]: The host node the returned inserts will be added to
  List<NodeBluePrint<dynamic>> inserts({required Node<dynamic> hostNode}) {
    return _inserts?.call(hostNode: hostNode) ?? [];
  }

  // ...........................................................................
  // Child builders

  /// A builder can define builders for child scopes
  ///
  /// Child builders are instantiated before parent builders.
  /// I.e. the parent's builders will be applied after the child builders.
  ///
  ///
  /// - Returns: A list of child builders
  List<ScBuilderBluePrint> children({required Scope hostScope}) {
    return _children?.call(hostScope: hostScope) ?? [];
  }

  // ...........................................................................
  /// Returns an example instance of the builder
  static ScBuilder get example {
    return ExampleScBuilderBluePrint.example;
  }

  /// The key of the builder
  final String key;

  // ...........................................................................
  /// When one of these suppliers change, the rebuild method will be called
  final List<String> needsUpdateSuppliers;

  /// Override this method to react to do something when one of the suppliers
  /// in [needsUpdateSuppliers] has a new product.
  ///
  /// [hostScope]: The scope this builder is instantiated in
  /// [components]: The latest components of the suppliers
  void needsUpdate({
    required Scope hostScope,
    required List<dynamic> components,
  }) {
    _needsUpdate?.call(hostScope: hostScope, components: components);
  }

  // ######################
  // Private
  // ######################

  // ######################
  // Private
  // ######################

  final List<ScopeBluePrint> Function({required Scope hostScope})? _addScopes;

  final ScopeBluePrint Function({
    required Scope hostScope,
    required ScopeBluePrint scopeToBeReplaced,
  })?
  _replaceScope;

  final List<NodeBluePrint<dynamic>>? Function({required Scope hostScope})?
  _addNodes;

  final NodeBluePrint<dynamic>? Function({
    required Scope hostScope,
    required Node<dynamic> nodeToBeReplaced,
  })?
  _replaceNode;

  final List<NodeBluePrint<dynamic>> Function({
    required Node<dynamic> hostNode,
  })?
  _inserts;

  final List<ScBuilderBluePrint> Function({required Scope hostScope})?
  _children;

  final void Function({
    required Scope hostScope,
    required List<dynamic> components,
  })?
  _needsUpdate;

  final bool Function(Scope scope)? _shouldProcessChildren;
  final bool Function(Scope scope)? _shouldProcessScope;
}

// #############################################################################
/// An example builder
class ExampleScBuilderBluePrint extends ScBuilderBluePrint {
  /// The constructor
  ExampleScBuilderBluePrint({
    super.key = 'exampleScBuilder',
    super.needsUpdateSuppliers,
  });

  // ...........................................................................
  @override
  bool shouldProcessChildren(Scope scope) {
    return true;
  }

  // ...........................................................................
  @override
  bool shouldProcessScope(Scope scope) {
    return true;
  }

  // ...........................................................................
  /// Inserts

  /// Will add two inserts "add111" and "p1MultiplyByTen" to all nodes
  /// starting with host
  @override
  List<NodeBluePrint<dynamic>> inserts({required Node<dynamic> hostNode}) {
    // Add an insert to all nodes which keys start with "host"
    if (hostNode.key.startsWith('host') && hostNode is Node<num>) {
      return [
        NodeBluePrint<num>(
          key: 'p0Add111',
          initialProduct: 0,
          produce: (components, previousProduct, node) {
            return previousProduct + 111;
          },
        ),
        NodeBluePrint<num>(
          key: 'p1MultiplyByTen',
          initialProduct: 0,
          produce: (components, previousProduct, node) {
            return previousProduct * 10;
          },
        ),
      ];
    }

    return super.inserts(hostNode: hostNode);
  }

  // ...........................................................................
  /// All scopes with key 'b' will get a child builder
  @override
  List<ScBuilderBluePrint> children({required Scope hostScope}) {
    return [if (hostScope.key == 'b') const ExampleChildScBuilderBluePrint()];
  }

  // ...........................................................................
  /// Returns an example instance of the ExampleScBuilder
  static ScBuilder get example {
    // The example applies inserts to all nodes with a key
    // starting with 'host'.

    // Let's create a node hiearchy with nodes starting with keys
    // starting with hosts
    final scope = Scope.example(
      builders: [
        ExampleScBuilderBluePrint(needsUpdateSuppliers: ['a/other']),
      ],
      children: [
        ScopeBluePrint.fromJson({
          'a': {
            'hostA': 0xA,
            'other': 1,
            'b': {'hostB': 0xB, 'hostC': 0xC},
          },
        }),
      ],
    );

    // Apply the builder to the scope
    scope.scm.flush();
    return scope.builders.first;
  }

  /// Returns how often needsUpdate was called
  Iterable<(Scope, List<dynamic> components)> get needsUpdateCalls =>
      _needsUpdateCalls;

  final List<(Scope, List<dynamic> components)> _needsUpdateCalls = [];

  // ...........................................................................
  @override
  void needsUpdate({
    required Scope hostScope,
    required List<dynamic> components,
  }) {
    super.needsUpdate(hostScope: hostScope, components: components);
    _needsUpdateCalls.add((hostScope, components));
  }

  @override
  void onInstantiate({required Scope hostScope}) {
    super.onInstantiate(hostScope: hostScope);

    // Create a node that counts how often onInstantiate was called
    final didCallOnInstantiate = hostScope.findOrCreateNode<num>(
      const NodeBluePrint<num>(key: 'didCallOnInstantiate', initialProduct: 0),
    );

    didCallOnInstantiate.product++;
  }
}

// #############################################################################
/// An example builder
class ExampleChildScBuilderBluePrint extends ScBuilderBluePrint {
  /// The constructor
  const ExampleChildScBuilderBluePrint({super.key = 'exampleChildScBuilder'});

  // ...........................................................................
  @override
  bool shouldProcessChildren(Scope scope) {
    return true;
  }

  // ...........................................................................
  @override
  bool shouldProcessScope(Scope scope) {
    return true;
  }

  // ...........................................................................
  /// Inserts

  /// Will an insert "c0MultiplyByTwo" to all nodes starting with host
  @override
  List<NodeBluePrint<dynamic>> inserts({required Node<dynamic> hostNode}) {
    // Add an insert to all nodes which keys start with "host"
    if (hostNode.key.startsWith('host') && hostNode is Node<num>) {
      return [
        NodeBluePrint<num>(
          key: 'c0MultiplyByTwo',
          initialProduct: 0,
          produce: (components, previousProduct, node) {
            return previousProduct * 2;
          },
        ),
      ];
    }

    return super.inserts(hostNode: hostNode);
  }
}
