// @license
// Copyright (c) 2019 - 2023 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:supply_chain/src/assembly_line.dart';
import 'package:supply_chain/src/node.dart';
import 'package:test/test.dart';

void main() {
  final assemblyLine = exampleAssemblyLine();
  final input = assemblyLine.input;
  final output = assemblyLine.output;
  final worker0 = Node.example();
  final worker1 = Node.example();
  final worker2 = Node.example();
  final worker3 = Node.example();
  final workers = assemblyLine.workers;

  group('AssemblyLine', () {
    // .........................................................................
    test('should throw if input == output', () {
      expect(
        () => exampleAssemblyLine(input: input, output: input),
        throwsA(
          isA<AssertionError>(),
        ),
      );
    });

    // .........................................................................
    test('should work fine', () {
      // Initially we have no workers
      expect(workers, isEmpty);

      // Connect input to output
      input.addCustomer(output);
      expect(input.customers, [output]);
      expect(output.suppliers, [input]);

      // Add a first worker.
      // It should be placed inbetween input and output
      assemblyLine.addWorker(worker0);
      expect(workers, [worker0]);
      expect(input.customers, [worker0]);
      expect(worker0.suppliers, [input]);
      expect(worker0.customers, [output]);
      expect(output.suppliers, [worker0]);

      // Add a second worker.
      // It should be placed between last worker and output
      assemblyLine.addWorker(worker1);
      expect(workers, [worker0, worker1]);
      expect(input.customers, [worker0]);
      expect(worker0.suppliers, [input]);
      expect(worker0.customers, [worker1]);
      expect(worker1.suppliers, [worker0]);
      expect(worker1.customers, [output]);
      expect(output.suppliers, [worker1]);

      // Add last added worker a second time
      // Nothing should happen
      assemblyLine.addWorker(worker1);
      expect(workers, [worker0, worker1]);

      // Add an earlier added worker again.
      // Should throw.
      expect(
        () => assemblyLine.addWorker(worker0),
        throwsA(
          predicate(
            (p0) =>
                p0 is ArgumentError &&
                p0.message == 'Worker is already in the previous chain',
          ),
        ),
      );

      // Add a third worker.
      // It should be placed between last worker and output
      assemblyLine.addWorker(worker2);
      expect(workers, [worker0, worker1, worker2]);
      expect(input.customers, [worker0]);
      expect(worker0.suppliers, [input]);
      expect(worker0.customers, [worker1]);
      expect(worker1.suppliers, [worker0]);
      expect(worker1.customers, [worker2]);
      expect(worker2.suppliers, [worker1]);
      expect(worker2.customers, [output]);
      expect(output.suppliers, [worker2]);

      // Add a fourth worker.
      // It should be placed between last worker and output
      assemblyLine.addWorker(worker3);
      expect(workers, [worker0, worker1, worker2, worker3]);
      expect(input.customers, [worker0]);
      expect(worker0.suppliers, [input]);
      expect(worker0.customers, [worker1]);
      expect(worker1.suppliers, [worker0]);
      expect(worker1.customers, [worker2]);
      expect(worker2.suppliers, [worker1]);
      expect(worker2.customers, [worker3]);
      expect(worker3.suppliers, [worker2]);
      expect(worker3.customers, [output]);
      expect(output.suppliers, [worker3]);

      // Remove first worker
      // Input should be connected to second worker
      // Removed worker should have no suppliers and customers anymore
      assemblyLine.removeWorker(worker0);
      expect(workers, [worker1, worker2, worker3]);
      expect(worker0.suppliers, <Node<dynamic>>[]);
      expect(worker0.customers, <Node<dynamic>>[]);
      expect(input.customers, [worker1]);
      expect(worker1.suppliers, [input]);
      expect(worker1.customers, [worker2]);
      expect(worker2.suppliers, [worker1]);
      expect(worker2.customers, [worker3]);
      expect(worker3.suppliers, [worker2]);
      expect(worker3.customers, [output]);
      expect(output.suppliers, [worker3]);

      // Remove second worker
      // Worker before and after should be connected with each other
      expect(workers.elementAt(1), worker2);
      assemblyLine.removeWorker(worker2);
      expect(workers, [worker1, worker3]);
      expect(worker2.suppliers, <Node<dynamic>>[]);
      expect(worker2.customers, <Node<dynamic>>[]);
      expect(input.customers, [worker1]);
      expect(worker1.suppliers, [input]);
      expect(worker1.customers, [worker3]);
      expect(worker3.suppliers, [worker1]);
      expect(worker3.suppliers, [worker1]);
      expect(worker3.customers, [output]);
      expect(output.suppliers, [worker3]);

      // Remove worker at the end
      // Second last worker should be connected with output
      expect(workers.last, worker3);
      assemblyLine.removeWorker(worker3);
      expect(workers, [worker1]);
      expect(worker3.suppliers, <Node<dynamic>>[]);
      expect(worker3.customers, <Node<dynamic>>[]);
      expect(input.customers, [worker1]);
      expect(worker1.suppliers, [input]);
      expect(worker1.customers, [output]);
      expect(output.suppliers, [worker1]);

      // Remove last remaining worker
      // Input should be connected to output
      expect(workers.length, 1);
      assemblyLine.removeWorker(worker1);
      expect(workers, <Node<dynamic>>[]);
      expect(worker1.suppliers, <Node<dynamic>>[]);
      expect(worker1.customers, <Node<dynamic>>[]);
      expect(input.customers, [output]);
      expect(output.suppliers, [input]);
    });
  });
}
