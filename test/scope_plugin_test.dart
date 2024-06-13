// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/supply_chain.dart';
import 'package:test/test.dart';

void main() {
  late Scope scope;

  setUp(() {
    scope = Scope.example();
  });

  group('ScopePlugin', () {
    test('example', () {
      expect(ScopePlugin.example(), isNotNull);
    });
    group('plugins', () {
      group('addPlugin(plugin)', () {
        group('should throw', () {
          test('if the plugin is already added', () {
            const plugin = ScopePlugin(overrides: {}, key: 'plugin');
            plugin.instantiate(scope: scope);
            expect(
              () => plugin.instantiate(scope: scope),
              throwsA(
                predicate<ArgumentError>(
                  (e) => e.toString().contains(
                        'Plugin already added.',
                      ),
                ),
              ),
            );
          });

          test('when there are multiple node plugins with the same key', () {
            final plugin0 = ScopePlugin(
              key: 'plugin0',
              overrides: {
                'node0': NodeBluePrint.example(key: 'key'),
                'node1': NodeBluePrint.example(key: 'key'),
              },
            );

            expect(
              () => plugin0.instantiate(scope: scope),
              throwsA(
                predicate<ArgumentError>(
                  (e) => e.toString().contains(
                        'Found multiple node plugins with key "key"',
                      ),
                ),
              ),
            );
          });
          test('when host nodes cannot be found', () {
            final plugin = ScopePlugin(
              key: 'plugin0',
              overrides: {
                'unknown0': NodeBluePrint.example(key: 'unknown'),
                'unknown1': NodeBluePrint.example(key: 'unknown1'),
              },
            );
            expect(
              () => plugin.instantiate(scope: scope),
              throwsA(
                predicate<ArgumentError>(
                  (e) => e.toString().contains(
                        'Host nodes not found: unknown0, unknown1',
                      ),
                ),
              ),
            );
          });

          test('when types of host nodes and plugin nodes do not match', () {
            final scope = Scope.example();
            scope.mockContent({
              'node0': 'string',
            });

            const plugin = ScopePlugin(
              key: 'plugin0',
              overrides: {
                'node0': NodeBluePrint<int>(key: 'plugin0', initialProduct: 0),
              },
            );

            expect(
              () => plugin.instantiate(scope: scope),
              throwsA(
                predicate<Error>(
                  (e) => e.toString().contains(
                        '\'Node<String>\' is not a subtype of type '
                        '\'Node<int>\' of \'host\'',
                      ),
                ),
              ),
            );
          });
        });

        test('should add the plugin to the list of plugins', () {
          const plugin = ScopePlugin(
            overrides: {},
            key: 'plugin0',
          );
          plugin.instantiate(scope: scope);
          expect(scope.plugins, [plugin]);
        });

        test('should add the node plugins to their corresponding hosts', () {
          // Define an existing node and scope hierarchy
          final scope = Scope.example();
          scope.mockContent({
            'a': {
              'b': {
                'n0': 0,
              },
              'c': {
                'n1': 0,
              },
            },
          });

          // Get the two nodes we want to add plugins to
          final node0 = scope.findNode<int>('a.b.n0')!;
          final node1 = scope.findNode<int>('a.c.n1')!;

          // Define a node plugin that modifies the two nodes
          final scopePlugin = ScopePlugin(
            key: 'plugin0',
            overrides: {
              'b.n0': NodeBluePrint<int>(
                key: 'byTwo',
                initialProduct: 0,
                produce: (components, previousProduct) =>
                    (components.first as int) * 2,
              ),
              'a.c.n1': NodeBluePrint<int>(
                key: 'byThree',
                initialProduct: 0,
                produce: (components, previousProduct) =>
                    (components.first as int) * 3,
              ),
            },
          );

          // Add the plugin to the scope
          scopePlugin.instantiate(scope: scope);

          // The plugins should have been added to the nodes
          expect(node0.plugins, hasLength(1));
          expect(node0.plugins.first.key, 'byTwo');
          expect(node1.plugins, hasLength(1));
          expect(node1.plugins.first.key, 'byThree');

          // Remove the plugin from the scope
          scopePlugin.dispose(scope: scope);

          // The plugins should have been removed from the nodes
          expect(node0.plugins, isEmpty);
          expect(node1.plugins, isEmpty);
        });
      });

      group('removePlugin(plugin)', () {
        group('should throw', () {
          test('if the plugin is not added', () {
            const plugin = ScopePlugin(
              key: 'plugin0',
              overrides: {},
            );
            expect(
              () => plugin.dispose(scope: scope),
              throwsA(
                predicate<ArgumentError>(
                  (e) => e.toString().contains(
                        'Plugin "plugin0" not found.',
                      ),
                ),
              ),
            );
          });

          test('if one of the plugin nodes in the plugin is not found', () {
            final scope = Scope.example();
            scope.mockContent({
              'node0': 0,
            });

            // Create a plugin with a node that does not exist
            const plugin = ScopePlugin(
              key: 'plugin0',
              overrides: {
                'node0':
                    NodeBluePrint<int>(key: 'pluginNode0', initialProduct: 0),
              },
            );

            // Add the plugin
            plugin.instantiate(scope: scope);

            // Remove the node that the plugin is supposed to modify
            final pluginNode = scope.findNode<int>('pluginNode0')!;
            pluginNode.dispose();

            // Try to remove the plugin
            expect(
              () => plugin.dispose(scope: scope),
              throwsA(
                predicate<ArgumentError>(
                  (e) => e.toString().contains(
                        'PluginNode with key "pluginNode0" not found.',
                      ),
                ),
              ),
            );
          });
        });

        test('should remove the plugin from the list of plugins', () {
          const plugin = ScopePlugin(
            key: 'plugin0',
            overrides: {},
          );
          plugin.instantiate(scope: scope);
          plugin.dispose(scope: scope);
          expect(scope.plugins, isEmpty);
        });

        test('should remove the node plugins from it\'s hosts', () {
          // Is tested in addPlugin()
        });
      });

      group('instantiate', () {
        test('should override build() nodes with nodes in overrides', () {
          final scope = Scope.example();
          scope.mockContent({
            'a': {
              'b': {
                'node0': 0,
              },
            },
          });

          ExampleScopePlugin(
            overrides: {
              'node0': NodeBluePrint.example(key: 'plugin0Override'),
            },
          ).instantiate(scope: scope);

          expect(scope.plugins, hasLength(1));
        });

        test('should add additional nodes with overrides', () {
          final scope = Scope.example();
          scope.mockContent({
            'a': {
              'b': {
                'node0': 0,
              },
              'c': {
                'node1': 1,
              },
            },
          });

          final node0 = scope.findNode<int>('a.b.node0')!;
          final node1 = scope.findNode<int>('a.c.node1')!;

          ExampleScopePlugin(
            // Replace node1 by node1Override
            overrides: {
              'node1': NodeBluePrint.example(key: 'plugin1Override'),
            },
          ).instantiate(scope: scope);

          expect(node0.plugins, hasLength(1));
          expect(node0.plugins.first.key, 'plugin0');

          expect(node1.plugins, hasLength(1));
          expect(node1.plugins.first.key, 'plugin1Override');
        });
      });
    });
  });
}
