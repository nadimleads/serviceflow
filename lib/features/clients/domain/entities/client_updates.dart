/// The three editable slices of a client, one per edit dialog on the profile.
///
/// Each maps to exactly the fields its dialog shows, so a save can never touch
/// anything the user did not see.
library;

class ClientBasicInfo {
  const ClientBasicInfo({
    required this.name,
    required this.phone,
    required this.address,
    required this.targetCountry,
  });

  final String name;
  final String phone;
  final String address;
  final String targetCountry;
}

class ClientFileInfo {
  const ClientFileInfo({
    required this.fileType,
    required this.fileStatus,
    required this.fileDetails,
    required this.givenPapers,
  });

  final String fileType;
  final String fileStatus;
  final String fileDetails;
  final String givenPapers;
}

class ClientPaymentInfo {
  const ClientPaymentInfo({
    required this.paidAmount,
    required this.paymentStatus,
  });

  /// Whole BDT, the total received so far (not a new payment).
  final int paidAmount;
  final String paymentStatus;
}
