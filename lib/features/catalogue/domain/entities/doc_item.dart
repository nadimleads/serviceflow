/// One entry in the document catalogue: a service the office sells, at a price.
class DocItem {
  const DocItem({
    required this.id,
    required this.name,
    required this.price,
    this.isAvailable = true,
  });

  final String id;
  final String name;

  /// Whole BDT.
  final int price;

  /// False means retired: hidden from the picker, still listed (struck
  /// through) in the catalogue so the CEO can relist it.
  final bool isAvailable;
}
