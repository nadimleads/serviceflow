import 'package:flutter_test/flutter_test.dart';
import 'package:serviceflow/features/clients/domain/entities/client_cart.dart';

void main() {
  const passport = CartLine(
    docItemId: 'passport',
    name: 'Passport',
    unitPrice: 500,
    quantity: 1,
  );
  const photo = CartLine(
    docItemId: 'photo',
    name: 'Photo',
    unitPrice: 50,
    quantity: 4,
  );

  group('CartLine', () {
    test('lineTotal is unit price times quantity', () {
      expect(photo.lineTotal, 200);
    });

    test('copyWith changes only the quantity', () {
      final copy = passport.copyWith(quantity: 3);
      expect(copy.quantity, 3);
      expect(copy.docItemId, 'passport');
      expect(copy.name, 'Passport');
      expect(copy.unitPrice, 500);
    });
  });

  group('ClientCart.merge', () {
    test('adds new lines and their amount to the running total', () {
      final cart = ClientCart.empty.merge([passport, photo]);

      expect(cart.lines.keys, ['passport', 'photo']);
      expect(cart.lines['photo']!.quantity, 4);
      expect(cart.totalAmount, 700);
    });

    test('adds to the quantity of a line already in the cart', () {
      final cart = ClientCart.empty
          .merge([passport])
          .merge([passport.copyWith(quantity: 2)]);

      expect(cart.lines['passport']!.quantity, 3);
      expect(cart.totalAmount, 1500);
    });

    test('takes name and price from the addition, moving the total by the '
        'added amount only', () {
      // A reprice between two visits: the line is re-added at the new price.
      final before = ClientCart.empty.merge([passport]);
      final after = before.merge([
        const CartLine(
          docItemId: 'passport',
          name: 'Passport (renewal)',
          unitPrice: 600,
          quantity: 1,
        ),
      ]);

      final line = after.lines['passport']!;
      expect(line.name, 'Passport (renewal)');
      expect(line.unitPrice, 600);
      expect(line.quantity, 2);

      // 500 already in the total, plus the 600 just added. This pins the
      // current accumulate-not-fold behaviour; see the ClientCart doc comment.
      expect(after.totalAmount, 1100);
    });

    test('ignores additions with no quantity', () {
      final cart = ClientCart.empty.merge([passport.copyWith(quantity: 0)]);

      expect(cart.isEmpty, isTrue);
      expect(cart.totalAmount, 0);
    });

    test('does not mutate the cart it was called on', () {
      final original = ClientCart.empty.merge([passport]);
      original.merge([photo]);

      expect(original.lines.keys, ['passport']);
      expect(original.totalAmount, 500);
    });
  });

  group('ClientCart.adjustQuantity', () {
    final cart = ClientCart.empty.merge([passport, photo]); // total 700

    test('returns null for a line that is not in the cart', () {
      expect(cart.adjustQuantity('visa', 1), isNull);
    });

    test('adds one unit price when incrementing', () {
      final updated = cart.adjustQuantity('photo', 1)!;

      expect(updated.lines['photo']!.quantity, 5);
      expect(updated.totalAmount, 750);
    });

    test('subtracts one unit price when decrementing above zero', () {
      final updated = cart.adjustQuantity('photo', -1)!;

      expect(updated.lines['photo']!.quantity, 3);
      expect(updated.totalAmount, 650);
    });

    test('removes the line and subtracts its whole amount at zero', () {
      final updated = cart.adjustQuantity('photo', -4)!;

      expect(updated.lines.containsKey('photo'), isFalse);
      expect(updated.totalAmount, 500);
    });

    test('a decrement past zero still removes the line cleanly', () {
      final updated = cart.adjustQuantity('passport', -5)!;

      expect(updated.lines.containsKey('passport'), isFalse);
      expect(updated.totalAmount, 200);
    });

    test('does not mutate the cart it was called on', () {
      cart.adjustQuantity('photo', -4);

      expect(cart.lines.keys, ['passport', 'photo']);
      expect(cart.totalAmount, 700);
    });
  });
}
