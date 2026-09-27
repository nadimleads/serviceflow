import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:serviceflow/core/utils/safe_read.dart';
import 'package:serviceflow/features/clients/domain/entities/client.dart';
import 'package:serviceflow/features/clients/domain/entities/client_updates.dart';
import 'package:serviceflow/features/clients/domain/entities/new_client.dart';

/// The `clients/{id}` document shape. The only place that knows its field
/// names, in either direction.
class ClientMapper {
  const ClientMapper._();

  static Client fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return Client(
      id: doc.id,
      code: asString(data['clientId']),
      name: asString(data['clientsname']),
      address: asString(data['address']),
      email: asString(data['email']),
      phone: asString(data['phone']),
      targetCountry: asString(data['targetCountry']),
      fileDetails: asString(data['fileDetails']),
      fileType: asString(data['fileType']),
      fileStatus: asString(data['fileStatus']),
      givenPapers: asString(data['givenPapers']),
      paymentStatus: asString(
        data['paymentStatus'],
        fallback: Client.duePaymentStatus,
      ),
      totalAmount: asInt(data['totalAmount']),
      paidAmount: asInt(data['paidAmount']),
      active: asBool(data['active']),
    );
  }

  /// The full document written at create time.
  static Map<String, dynamic> toCreateMap(
    NewClient draft, {
    required String code,
  }) {
    return {
      'clientId': code,
      'clientsname': draft.name,
      'address': draft.address,
      'email': draft.email,
      'phone': draft.phone,
      'targetCountry': draft.targetCountry,
      'fileDetails': draft.fileDetails,
      'fileType': draft.fileType,
      'fileStatus': Client.openedFileStatus,
      'givenPapers': draft.givenPapers,
      'paymentStatus': Client.duePaymentStatus,
      'totalAmount': 0,
      'paidAmount': 0,
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  static Map<String, dynamic> basicInfoToMap(ClientBasicInfo info) {
    return {
      'clientsname': info.name,
      'phone': info.phone,
      'address': info.address,
      'targetCountry': info.targetCountry,
    };
  }

  static Map<String, dynamic> fileInfoToMap(ClientFileInfo info) {
    return {
      'fileType': info.fileType,
      'fileStatus': info.fileStatus,
      'fileDetails': info.fileDetails,
      'givenPapers': info.givenPapers,
    };
  }

  static Map<String, dynamic> paymentInfoToMap(ClientPaymentInfo info) {
    return {
      'paidAmount': info.paidAmount,
      'paymentStatus': info.paymentStatus,
    };
  }

  static Map<String, dynamic> activeToMap(bool active) => {'active': active};

  static Map<String, dynamic> paymentStatusToMap(String status) {
    return {'paymentStatus': status};
  }

  static Map<String, dynamic> totalAmountToMap(int totalAmount) {
    return {'totalAmount': totalAmount};
  }
}
