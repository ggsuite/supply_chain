// @license
// Copyright (c) 2025 Dr. Gabriel Gatzsche
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';

class TestGraphs {
  TestGraphs() {
    butterFly = ButterFlyExample(withScopes: true);

    allScopeKeys = butterFly.x.scope.pathArray;

    s111 = butterFly.s111;
    s11 = butterFly.s11;
    s10 = butterFly.s10;
    s01 = butterFly.s01;
    s00 = butterFly.s00;
    s1 = butterFly.s1;
    s0 = butterFly.s0;
    x = butterFly.x;
    c0 = butterFly.c0;
    c1 = butterFly.c1;
    c00 = butterFly.c00;
    c01 = butterFly.c01;
    c10 = butterFly.c10;
    c11 = butterFly.c11;
    c111 = butterFly.c111;
    level0 = butterFly.level0;
    level1 = butterFly.level1;
    level2 = butterFly.level2;
    level3 = butterFly.level3;

    allNodes = x.scope.scm.nodes.where((n) => !n.scope.isMetaScope).toList();
    allScopes = butterFly.allScopes;
    allNodeKeys = allNodes.map((n) => n.key).toList();
    assert(level2.key == 'level2');
    assert(level3.key == 'level3');

    graph = const Graph();

    x.scm.flush();
  }

  // ...........................................................................

  late ButterFlyExample butterFly;
  late List<String> allScopeKeys;

  late List<Node<dynamic>> allNodes;
  late List<Scope> allScopes;
  late List<String> allNodeKeys;

  late Graph graph;

  late Node<String> s111;
  late Node<String> s11;
  late Node<String> s10;
  late Node<String> s01;
  late Node<String> s00;
  late Node<String> s1;
  late Node<String> s0;
  late Node<String> x;
  late Node<String> c0;
  late Node<String> c1;
  late Node<String> c00;
  late Node<String> c01;
  late Node<String> c10;
  late Node<String> c11;
  late Node<String> c111;
  late Scope level0;
  late Scope level1;
  late Scope level2;
  late Scope level3;
}
