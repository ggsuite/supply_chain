// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:supply_chain/supply_chain.dart';

/// Result of one benchmark scenario
class BenchResult {
  BenchResult({
    required this.name,
    required this.nodes,
    required this.setupMs,
    required this.updates,
    required this.updateTotalMs,
    required this.verified,
  });

  final String name;
  final int nodes;
  final double setupMs;
  final int updates;
  final double updateTotalMs;
  final bool verified;

  double get perUpdateUs => updateTotalMs * 1000 / updates;

  Map<String, dynamic> toJson() => {
    'name': name,
    'nodes': nodes,
    'setupMs': setupMs,
    'updates': updates,
    'updateTotalMs': updateTotalMs,
    'perUpdateUs': perUpdateUs,
    'verified': verified,
  };
}

// .............................................................................
NodeBluePrint<int> _source(String key) =>
    NodeBluePrint<int>(key: key, initialProduct: 0);

NodeBluePrint<int> _worker(String key, List<String> suppliers) =>
    NodeBluePrint<int>(
      key: key,
      initialProduct: 0,
      suppliers: suppliers,
      produce: (components, previous, node) {
        var sum = 1;
        for (final c in components) {
          sum += c as int;
        }
        return sum;
      },
    );

// .............................................................................
/// Builds a linear chain: n0 -> n1 -> ... -> n(n-1)
BenchResult chain(int n, int updates) {
  final sw = Stopwatch()..start();
  final scm = Scm(isTest: true);
  final scope = Scope.root(key: 'bench', scm: scm);

  Node<int>(bluePrint: _source('n0'), scope: scope);
  for (var i = 1; i < n; i++) {
    Node<int>(bluePrint: _worker('n$i', ['n${i - 1}']), scope: scope);
  }
  scm.flush();
  final setupMs = sw.elapsedMicroseconds / 1000;

  final first = scope.findNode<int>('n0')!;
  final last = scope.findNode<int>('n${n - 1}')!;

  sw
    ..reset()
    ..start();
  for (var u = 1; u <= updates; u++) {
    first.product = u;
    scm.flush();
  }
  final updateTotalMs = sw.elapsedMicroseconds / 1000;

  // Each hop adds 1 to the sum of its single supplier.
  final verified = last.product == updates + n - 1;

  return BenchResult(
    name: 'chain(n=$n)',
    nodes: n,
    setupMs: setupMs,
    updates: updates,
    updateTotalMs: updateTotalMs,
    verified: verified,
  );
}

// .............................................................................
/// One root supplying n customers
BenchResult fanOut(int n, int updates) {
  final sw = Stopwatch()..start();
  final scm = Scm(isTest: true);
  final scope = Scope.root(key: 'bench', scm: scm);

  Node<int>(bluePrint: _source('root'), scope: scope);
  for (var i = 0; i < n; i++) {
    Node<int>(bluePrint: _worker('c$i', ['root']), scope: scope);
  }
  scm.flush();
  final setupMs = sw.elapsedMicroseconds / 1000;

  final root = scope.findNode<int>('root')!;
  final lastLeaf = scope.findNode<int>('c${n - 1}')!;

  sw
    ..reset()
    ..start();
  for (var u = 1; u <= updates; u++) {
    root.product = u;
    scm.flush();
  }
  final updateTotalMs = sw.elapsedMicroseconds / 1000;

  final verified = lastLeaf.product == updates + 1;

  return BenchResult(
    name: 'fanOut(n=$n)',
    nodes: n + 1,
    setupMs: setupMs,
    updates: updates,
    updateTotalMs: updateTotalMs,
    verified: verified,
  );
}

// .............................................................................
/// n sources supplying one sink
BenchResult fanIn(int n, int updates) {
  final sw = Stopwatch()..start();
  final scm = Scm(isTest: true);
  final scope = Scope.root(key: 'bench', scm: scm);

  final supplierKeys = <String>[];
  for (var i = 0; i < n; i++) {
    Node<int>(bluePrint: _source('s$i'), scope: scope);
    supplierKeys.add('s$i');
  }
  Node<int>(bluePrint: _worker('sink', supplierKeys), scope: scope);
  scm.flush();
  final setupMs = sw.elapsedMicroseconds / 1000;

  final s0 = scope.findNode<int>('s0')!;
  final sink = scope.findNode<int>('sink')!;

  sw
    ..reset()
    ..start();
  for (var u = 1; u <= updates; u++) {
    s0.product = u;
    scm.flush();
  }
  final updateTotalMs = sw.elapsedMicroseconds / 1000;

  final verified = sink.product == updates + 1;

  return BenchResult(
    name: 'fanIn(n=$n)',
    nodes: n + 1,
    setupMs: setupMs,
    updates: updates,
    updateTotalMs: updateTotalMs,
    verified: verified,
  );
}

// .............................................................................
/// Layered DAG: `width` sources, `depth` layers; every node of layer l
/// depends on two nodes of layer l-1 (diamond-heavy).
BenchResult layered(int width, int depth, int updates) {
  final sw = Stopwatch()..start();
  final scm = Scm(isTest: true);
  final scope = Scope.root(key: 'bench', scm: scm);

  for (var i = 0; i < width; i++) {
    Node<int>(bluePrint: _source('l0x$i'), scope: scope);
  }
  for (var l = 1; l < depth; l++) {
    for (var i = 0; i < width; i++) {
      Node<int>(
        bluePrint: _worker('l${l}x$i', [
          'l${l - 1}x$i',
          'l${l - 1}x${(i + 1) % width}',
        ]),
        scope: scope,
      );
    }
  }
  scm.flush();
  final setupMs = sw.elapsedMicroseconds / 1000;

  final source = scope.findNode<int>('l0x0')!;
  final sink = scope.findNode<int>('l${depth - 1}x0')!;
  final sinkBefore = sink.product;

  sw
    ..reset()
    ..start();
  for (var u = 1; u <= updates; u++) {
    source.product = u;
    scm.flush();
  }
  final updateTotalMs = sw.elapsedMicroseconds / 1000;

  final verified = sink.product != sinkBefore;

  return BenchResult(
    name: 'layered(w=$width,d=$depth)',
    nodes: width * depth,
    setupMs: setupMs,
    updates: updates,
    updateTotalMs: updateTotalMs,
    verified: verified,
  );
}

// .............................................................................
/// Updates all sources of a layered DAG at once and flushes - measures bulk
/// invalidation where many nodes are prepared at the same time.
BenchResult bulkUpdate(int width, int depth, int updates) {
  final sw = Stopwatch()..start();
  final scm = Scm(isTest: true);
  final scope = Scope.root(key: 'bench', scm: scm);

  for (var i = 0; i < width; i++) {
    Node<int>(bluePrint: _source('l0x$i'), scope: scope);
  }
  for (var l = 1; l < depth; l++) {
    for (var i = 0; i < width; i++) {
      Node<int>(
        bluePrint: _worker('l${l}x$i', [
          'l${l - 1}x$i',
          'l${l - 1}x${(i + 1) % width}',
        ]),
        scope: scope,
      );
    }
  }
  scm.flush();
  final setupMs = sw.elapsedMicroseconds / 1000;

  final sources = [
    for (var i = 0; i < width; i++) scope.findNode<int>('l0x$i')!,
  ];
  final sink = scope.findNode<int>('l${depth - 1}x0')!;
  final sinkBefore = sink.product;

  sw
    ..reset()
    ..start();
  for (var u = 1; u <= updates; u++) {
    for (final source in sources) {
      source.product = u;
    }
    scm.flush();
  }
  final updateTotalMs = sw.elapsedMicroseconds / 1000;

  final verified = sink.product != sinkBefore;

  return BenchResult(
    name: 'bulkUpdate(w=$width,d=$depth)',
    nodes: width * depth,
    setupMs: setupMs,
    updates: updates,
    updateTotalMs: updateTotalMs,
    verified: verified,
  );
}

// .............................................................................
/// Instantiates a chain of nested ScopeBluePrints - measures scope and
/// builder machinery during blueprint driven construction.
BenchResult nestedScopes(int depth, int nodesPerScope) {
  final sw = Stopwatch()..start();
  final scm = Scm(isTest: true);
  final root = Scope.root(key: 'bench', scm: scm);

  var bp = ScopeBluePrint(
    key: 'level0',
    nodes: [
      for (var i = 0; i < nodesPerScope; i++)
        NodeBluePrint<int>(key: 'n$i', initialProduct: 0),
    ],
  );
  for (var d = 1; d < depth; d++) {
    bp = ScopeBluePrint(
      key: 'level$d',
      nodes: [
        for (var i = 0; i < nodesPerScope; i++)
          NodeBluePrint<int>(key: 'n$i', initialProduct: 0),
      ],
      children: [bp],
    );
  }

  final scope = bp.instantiate(scope: root);
  scm.flush();
  final setupMs = sw.elapsedMicroseconds / 1000;

  final verified = scope.findNode<int>('level0/n0') != null;

  return BenchResult(
    name: 'nestedScopes(d=$depth,n=$nodesPerScope)',
    nodes: depth * nodesPerScope,
    setupMs: setupMs,
    updates: 1,
    updateTotalMs: 0,
    verified: verified,
  );
}

// .............................................................................
/// Linear chain like [chain], but with drainMode enabled: all waves of an
/// update are processed within a single production cycle.
BenchResult drainChain(int n, int updates) {
  final sw = Stopwatch()..start();
  final scm = Scm(isTest: true)..drainMode = true;
  final scope = Scope.root(key: 'bench', scm: scm);

  Node<int>(bluePrint: _source('n0'), scope: scope);
  for (var i = 1; i < n; i++) {
    Node<int>(bluePrint: _worker('n$i', ['n${i - 1}']), scope: scope);
  }
  scm.flush();
  final setupMs = sw.elapsedMicroseconds / 1000;

  final first = scope.findNode<int>('n0')!;
  final last = scope.findNode<int>('n${n - 1}')!;

  sw
    ..reset()
    ..start();
  for (var u = 1; u <= updates; u++) {
    first.product = u;
    scm.flush();
  }
  final updateTotalMs = sw.elapsedMicroseconds / 1000;

  final verified = last.product == updates + n - 1;

  return BenchResult(
    name: 'drainChain(n=$n)',
    nodes: n,
    setupMs: setupMs,
    updates: updates,
    updateTotalMs: updateTotalMs,
    verified: verified,
  );
}

// .............................................................................
/// Linear chain driven in non-test mode (microtasks + real timers) - the
/// production configuration of the scm.
Future<BenchResult> chainProductionMode(int n, int updates) async {
  final sw = Stopwatch()..start();
  final scm = Scm(isTest: false);
  final scope = Scope.root(key: 'bench', scm: scm);

  Node<int>(bluePrint: _source('n0'), scope: scope);
  for (var i = 1; i < n; i++) {
    Node<int>(bluePrint: _worker('n$i', ['n${i - 1}']), scope: scope);
  }

  final first = scope.findNode<int>('n0')!;
  final last = scope.findNode<int>('n${n - 1}')!;

  // Wait for initial production to settle
  while (last.product != n - 1) {
    await Future<void>.delayed(Duration.zero);
    scm.tick();
  }
  final setupMs = sw.elapsedMicroseconds / 1000;

  sw
    ..reset()
    ..start();
  for (var u = 1; u <= updates; u++) {
    first.product = u;
    while (last.product != u + n - 1) {
      await Future<void>.delayed(Duration.zero);
      scm.tick();
    }
  }
  final updateTotalMs = sw.elapsedMicroseconds / 1000;

  final verified = last.product == updates + n - 1;

  return BenchResult(
    name: 'chainProductionMode(n=$n)',
    nodes: n,
    setupMs: setupMs,
    updates: updates,
    updateTotalMs: updateTotalMs,
    verified: verified,
  );
}

// .............................................................................
void main(List<String> args) async {
  String? out;
  var label = 'run';
  var quick = false;
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--out' && i + 1 < args.length) out = args[i + 1];
    if (args[i] == '--label' && i + 1 < args.length) label = args[i + 1];
    if (args[i] == '--quick') quick = true;
  }

  final f = quick ? 10 : 1;

  // Warmup (JIT)
  chain(50, 10);
  fanOut(50, 10);
  fanIn(50, 10);
  layered(4, 4, 10);

  final results = <BenchResult>[
    chain(100, 100),
    chain(1000 ~/ f, 100),
    chain(3000 ~/ f, 10),
    fanOut(100, 100),
    fanOut(1000 ~/ f, 100),
    fanIn(100, 100),
    fanIn(1000 ~/ f, 100),
    layered(10, 10, 100),
    layered(32, 16 ~/ (quick ? 2 : 1), 50),
    bulkUpdate(64, 8, 50),
    nestedScopes(150 ~/ f, 10),
    drainChain(1000 ~/ f, 100),
    await chainProductionMode(500 ~/ f, 20),
  ];

  print(
    '| scenario | nodes | setup ms | updates | total ms | per update µs |'
    ' ok |',
  );
  print('|---|---|---|---|---|---|---|');
  for (final r in results) {
    print(
      '| ${r.name} | ${r.nodes} | ${r.setupMs.toStringAsFixed(1)} '
      '| ${r.updates} | ${r.updateTotalMs.toStringAsFixed(1)} '
      '| ${r.perUpdateUs.toStringAsFixed(1)} '
      '| ${r.verified ? '✓' : '✗ FAILED'} |',
    );
  }

  if (out != null) {
    File(out).writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'label': label,
        'results': results.map((r) => r.toJson()).toList(),
      }),
    );
    print('\nWrote $out');
  }

  final allVerified = results.every((r) => r.verified);
  if (!allVerified) {
    print('\nERROR: some scenarios produced wrong results!');
    exitCode = 1;
  }
}
