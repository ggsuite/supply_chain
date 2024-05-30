# Changelog

## [Unreleased]

### Added

- Add SubChainManagerBluePrint
- Add SubScopeManager
- Add boilerplate for SubScopeManager
- Add Scope.dispose
- Add path to node and scope. Allow to specify a scope in supplier keys
- Add built method to ScopeBluePrint
- Add Scope.mockContent
- Add Scope.findScope
- Add Scope.root

### Changed

- Turn NodeBluePrint into const constructor
- Make sure disposing a node removes it from the SCM and it's scope
- SubScopeManager can dynamically create new sub scopes
- Node and scope names must be camel case now
- Scope:instantiate: Rename parentScope param into scope
- ScopeBluePrints will alwas create a scope
- Rename subScope to childScope
- Breaking change: Use . instead / for scope notation
- Ignore code not executed on GitHub
- Allow to embedd real ScopeBluePrints into mockContent
- Rework example

### Removed

- Removed plant
- Remove dependencies from ScopeBluePrint

## [1.0.13] - 2024-05-17

### Added

- Add possibility to instantiate a scope blue print right within parent scope
- Add class NodeConfig
- Add NodeConfig to Node
- Add SupplyChain:findOrCreateNodes
- Add ScopeBluePrint

### Changed

- Switch to absolute imports
- A node's product can now be set from the outside
- SupplyChain finds or creates nodes based on config
- Update graph files on disk, separate nodes and edges in dot file
- Write graphs to webp
- Rename SupplyChain into Scope
- Rename NodeConfig into NodeBluePrint

### Removed

- Remove findOrCreateNodes because type cannot be inferred

## [1.0.12] - 2024-05-10

### Changed

- Rename createNode into findOrCreateNode

## [1.0.11] - 2024-05-10

- Add `equalsGraph`
- Make `findNode` finding arbitrary nodes

### Changed

- Updated version in pubspec.yaml

### Removed

- Remove ScmNodeInterface, find arbitrary nodes by SupplyChain:findNode

## [1.0.10] - 2024-05-10

## [1.0.9] - 2024-05-10

### Changed

- Nodes can be found in direct children
- Supply chains need a parent chain from beginning

## [1.0.8] - 2024-05-10

### Added

- Add option to findNode

## [1.0.7] - 2024-05-08

### Added

- Add SupplyChain.hasNode

## [1.0.6] - 2024-05-08

### Removed

- Remove print statement

## [1.0.5] - 2024-05-08

### Fixed

- Fix issues in supply chain

## [1.0.4] - 2024-05-08

### Changed

- Rename scope into chain

## [1.0.3] - 2024-05-08

### Changed

- Renamed name into key

## [1.0.2] - 2024-05-08

### Changed

- Rename name into key
- Rename Scope into SupplyChain

## [1.0.1] - 2024-05-08

### Added

- Add Scope
- Add Scope class + print scopes using dot
- Add isDescendantOf, isAncestorOf, initSuppliers
- Add ValueNode

### Changed

- Scopes can build an hierrarchy
- Hand over components and previous value to produce method

### Removed

- Removed needsUpdate because it is not used

## [1.0.0] - 2024-05-04

### Changed

- Rename gg\_supply\_chain into supply\_chain
- Updated version
- Upgraded gg\_fake\_timer
- 'Pipline: Disable cache'
- 'publish\_to: none for private repositories'
- Rework changelog
- 'Github Actions Pipeline'
- 'Github Actions Pipeline: Add SDK file containing flutter into .github/workflows to make github installing flutter and not dart SDK'

[Unreleased]: https://github.com/inlavigo/supply_chain/compare/1.0.13...HEAD
[1.0.13]: https://github.com/inlavigo/supply_chain/compare/1.0.12...1.0.13
[1.0.12]: https://github.com/inlavigo/supply_chain/compare/1.0.11...1.0.12
[1.0.11]: https://github.com/inlavigo/supply_chain/compare/1.0.10...1.0.11
[1.0.10]: https://github.com/inlavigo/supply_chain/compare/1.0.9...1.0.10
[1.0.9]: https://github.com/inlavigo/supply_chain/compare/1.0.8...1.0.9
[1.0.8]: https://github.com/inlavigo/supply_chain/compare/1.0.7...1.0.8
[1.0.7]: https://github.com/inlavigo/supply_chain/compare/1.0.6...1.0.7
[1.0.6]: https://github.com/inlavigo/supply_chain/compare/1.0.5...1.0.6
[1.0.5]: https://github.com/inlavigo/supply_chain/compare/1.0.4...1.0.5
[1.0.4]: https://github.com/inlavigo/supply_chain/compare/1.0.3...1.0.4
[1.0.3]: https://github.com/inlavigo/supply_chain/compare/1.0.2...1.0.3
[1.0.2]: https://github.com/inlavigo/supply_chain/compare/1.0.1...1.0.2
[1.0.1]: https://github.com/inlavigo/supply_chain/compare/1.0.0...1.0.1
[1.0.0]: https://github.com/inlavigo/supply_chain/tag/%tag
