import 'package:supply_chain/src/node.dart';
import 'package:supply_chain/src/producer.dart';
import 'package:test/test.dart';

// #############################################################################
class DerivedProducer extends Producer<int> {
  DerivedProducer({required super.worker});

  // Override the input node -> Is not the same as output anymore
  @override
  Node<int> get input => _input;

  final Node<int> _input = exampleNode();
}

// #############################################################################
void main() {
  final producer = exampleProducer();

  group('Producer', () {
    // #########################################################################

    test('input, output', () {
      // Most simple producer: input == worker == output
      expect(producer.input, producer.output);
      expect(producer.input, producer.worker);
    });

    // .........................................................................
    test('addSupplier, removeSupplier, addCustomer, removeCustomer', () {
      // Create a producer where input != output
      final producer = DerivedProducer(worker: exampleNode());
      expect(producer.input, isNot(producer.output));

      // addSupplier should add supplier to input
      final supplier = exampleNode();
      producer.addSupplier(supplier);
      expect(producer.output.suppliers, <Node<dynamic>>[]);
      expect(producer.input.suppliers, [supplier]);

      // removeSupplier should remove supplier from input
      producer.removeSupplier(supplier);
      expect(producer.input.suppliers, <Node<dynamic>>[]);

      // addCustomer/removeCustomer should add/remove customer to output
      final customer = exampleNode();
      producer.addCustomer(customer);
      expect(producer.input.customers, <Node<dynamic>>[]);
      expect(producer.output.customers, [customer]);

      // removeCustomer should remove customer from output
      producer.removeCustomer(customer);
      expect(producer.output.customers, <Node<dynamic>>[]);
    });
  });
}
