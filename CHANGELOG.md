# Changelog

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
