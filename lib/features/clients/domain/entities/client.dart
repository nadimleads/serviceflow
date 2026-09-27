/// A client of the consultancy: identity, the file being processed for them,
/// and the money side of it.
///
/// Field names here are the app's vocabulary. The Firestore spelling of each
/// one lives in the data layer's `ClientMapper` and nowhere else.
class Client {
  const Client({
    required this.id,
    required this.code,
    required this.name,
    this.address = '',
    this.email = '',
    this.phone = '',
    this.targetCountry = '',
    this.fileDetails = '',
    this.fileType = '',
    this.fileStatus = '',
    this.givenPapers = '',
    this.paymentStatus = duePaymentStatus,
    this.totalAmount = 0,
    this.paidAmount = 0,
    this.active = false,
  });

  /// The file status every client starts in.
  static const String openedFileStatus = 'File Opened';

  /// Payment status vocabulary. Free text in the database today, so these are
  /// the two values the app itself writes and checks.
  static const String duePaymentStatus = 'Due';
  static const String fullyPaidStatus = 'Fully Paid';

  /// The Firestore document ID.
  final String id;

  /// The human-facing code such as `C001`. Currently also used as [id].
  final String code;

  final String name;
  final String address;
  final String email;
  final String phone;
  final String targetCountry;

  final String fileDetails;
  final String fileType;
  final String fileStatus;
  final String givenPapers;

  final String paymentStatus;

  /// Whole BDT. The running total of the needed documents, as the cart keeps it.
  final int totalAmount;
  final int paidAmount;

  final bool active;

  /// What is still owed. Never negative: an overpayment shows as zero due.
  int get payableAmount {
    final due = totalAmount - paidAmount;
    return due < 0 ? 0 : due;
  }

  bool get isFullyPaid => paymentStatus == fullyPaidStatus;

  /// Formats the client counter into a display code: 1 becomes `C001`.
  static String codeFor(int sequence) {
    return 'C${sequence.toString().padLeft(3, '0')}';
  }
}
