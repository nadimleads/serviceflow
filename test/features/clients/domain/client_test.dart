import 'package:flutter_test/flutter_test.dart';
import 'package:serviceflow/features/clients/domain/entities/client.dart';

void main() {
  Client client({
    int total = 0,
    int paid = 0,
    String status = Client.duePaymentStatus,
  }) {
    return Client(
      id: 'C001',
      code: 'C001',
      name: 'Test Client',
      totalAmount: total,
      paidAmount: paid,
      paymentStatus: status,
    );
  }

  group('Client.payableAmount', () {
    test('is what remains after payments', () {
      expect(client(total: 5000, paid: 2000).payableAmount, 3000);
    });

    test('is zero when nothing has been billed', () {
      expect(client().payableAmount, 0);
    });

    test('never goes negative on an overpayment', () {
      expect(client(total: 1000, paid: 1500).payableAmount, 0);
    });
  });

  test('isFullyPaid checks the exact status the app writes', () {
    expect(client(status: Client.fullyPaidStatus).isFullyPaid, isTrue);
    expect(client(status: Client.duePaymentStatus).isFullyPaid, isFalse);
    expect(client(status: 'fully paid').isFullyPaid, isFalse);
  });

  group('Client.codeFor', () {
    test('pads the sequence to three digits', () {
      expect(Client.codeFor(1), 'C001');
      expect(Client.codeFor(42), 'C042');
      expect(Client.codeFor(999), 'C999');
    });

    test('does not truncate beyond three digits', () {
      expect(Client.codeFor(1234), 'C1234');
    });
  });
}
