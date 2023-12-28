// @license
// Copyright (c) 2019 - 2023 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'node.dart';

/// Interface used by nodes to communicate with its supply chain manager
abstract class ScmNodeInterface {
  // ...........................................................................
  // Register nodes

  /// Adds a node to scm
  void addNode(Node node);

  /// Removes the node from scm
  void removeNode(Node node);

  // ...........................................................................
  // Animate nodes

  /// Calling this method will nominate the node on each tick
  void animateNode(Node node);

  /// Calling this method will not nominate the node on each tick anymore
  void deanimateNode(Node node);

  // ...........................................................................
  // Prioritization
  void priorityHasChanged(Node node);

  // ...........................................................................
  // Production live cycle

  /// Nominate node for production
  void nominate(Node node);

  /// Inform scm about an update
  void hasNewProduct(Node node);
}
