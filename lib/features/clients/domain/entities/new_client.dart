/// Everything the Add Client form collects.
///
/// The rest of a `Client` — code, statuses, amounts, active flag — is set by
/// the system at create time, not typed by the user.
class NewClient {
  const NewClient({
    required this.name,
    required this.address,
    required this.email,
    required this.phone,
    required this.targetCountry,
    required this.fileDetails,
    required this.fileType,
    required this.givenPapers,
  });

  final String name;
  final String address;
  final String email;
  final String phone;
  final String targetCountry;
  final String fileDetails;
  final String fileType;
  final String givenPapers;
}
