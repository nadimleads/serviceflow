/// One needed document on a client's file, with the price it was added at.
class CartLine {
  const CartLine({
    required this.docItemId,
    required this.name,
    required this.unitPrice,
    required this.quantity,
  });

  /// The catalogue item this line came from.
  final String docItemId;

  final String name;

  /// Whole BDT.
  final int unitPrice;

  final int quantity;

  int get lineTotal => unitPrice * quantity;

  CartLine copyWith({int? quantity}) {
    return CartLine(
      docItemId: docItemId,
      name: name,
      unitPrice: unitPrice,
      quantity: quantity ?? this.quantity,
    );
  }
}

/// The documents a client needs, keyed by catalogue item ID, plus the stored
/// running total.
///
/// [totalAmount] is kept as written rather than re-derived from [lines]:
/// [merge] and [adjustQuantity] move it by exactly the amount they add or
/// remove, which is how the app has always maintained it. Folding it from the
/// lines instead is decision 6 in docs/BUILD_PLAN.md — a deliberate behaviour
/// change for a later stage, not part of a refactor.
class ClientCart {
  const ClientCart({required this.lines, required this.totalAmount});

  static const ClientCart empty = ClientCart(lines: {}, totalAmount: 0);

  final Map<String, CartLine> lines;
  final int totalAmount;

  bool get isEmpty => lines.isEmpty;

  /// Adds [additions] to the cart.
  ///
  /// An item already present has the new quantity added to it and takes the
  /// addition's name and unit price (the catalogue values at the time of
  /// adding). Additions with no quantity are ignored. Returns a new cart.
  ClientCart merge(Iterable<CartLine> additions) {
    final merged = Map<String, CartLine>.of(lines);
    var added = 0;

    for (final addition in additions) {
      if (addition.quantity <= 0) continue;
      final existing = merged[addition.docItemId];
      merged[addition.docItemId] = addition.copyWith(
        quantity: (existing?.quantity ?? 0) + addition.quantity,
      );
      added += addition.lineTotal;
    }

    return ClientCart(lines: merged, totalAmount: totalAmount + added);
  }

  /// Moves one line's quantity by [delta]. Reaching zero removes the line.
  ///
  /// Returns null when [docItemId] is not in the cart: nothing to write.
  ClientCart? adjustQuantity(String docItemId, int delta) {
    final line = lines[docItemId];
    if (line == null) return null;

    final updated = Map<String, CartLine>.of(lines);
    final quantity = line.quantity + delta;

    if (quantity <= 0) {
      updated.remove(docItemId);
      return ClientCart(
        lines: updated,
        totalAmount: totalAmount - line.lineTotal,
      );
    }

    updated[docItemId] = line.copyWith(quantity: quantity);
    return ClientCart(
      lines: updated,
      totalAmount: totalAmount + line.unitPrice * delta,
    );
  }
}
