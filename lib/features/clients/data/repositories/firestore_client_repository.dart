import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:serviceflow/core/utils/safe_read.dart';
import 'package:serviceflow/features/clients/data/mappers/client_cart_mapper.dart';
import 'package:serviceflow/features/clients/data/mappers/client_mapper.dart';
import 'package:serviceflow/features/clients/domain/entities/client.dart';
import 'package:serviceflow/features/clients/domain/entities/client_cart.dart';
import 'package:serviceflow/features/clients/domain/entities/client_updates.dart';
import 'package:serviceflow/features/clients/domain/entities/new_client.dart';
import 'package:serviceflow/features/clients/domain/repositories/client_repository.dart';

/// [ClientRepository] backed by Firestore.
///
/// Collections: `clients/{id}` for the record, `clients/{id}/neededDocs/cartDocs`
/// for the cart, and `counters/clientCounter` for the sequential client code.
/// Every write that touches two documents runs in a transaction.
class FirestoreClientRepository implements ClientRepository {
  FirestoreClientRepository(this._db);

  final FirebaseFirestore _db;

  static const _clientsCollection = 'clients';
  static const _countersCollection = 'counters';
  static const _clientCounterDoc = 'clientCounter';
  static const _neededDocsCollection = 'neededDocs';
  static const _cartDoc = 'cartDocs';

  CollectionReference<Map<String, dynamic>> get _clients {
    return _db.collection(_clientsCollection);
  }

  DocumentReference<Map<String, dynamic>> _cartRef(String clientId) {
    return _clients.doc(clientId).collection(_neededDocsCollection).doc(_cartDoc);
  }

  @override
  Stream<List<Client>> watchClients() {
    return _clients.snapshots().map(
      (snapshot) => snapshot.docs.map(ClientMapper.fromDoc).toList(),
    );
  }

  @override
  Stream<Client?> watchClient(String clientId) {
    return _clients.doc(clientId).snapshots().map(
      (doc) => doc.exists ? ClientMapper.fromDoc(doc) : null,
    );
  }

  @override
  Future<String> createClient(NewClient draft) {
    final counterRef = _db.collection(_countersCollection).doc(_clientCounterDoc);

    // A transaction, not a read-then-write: two people tapping Create at the
    // same moment must not be handed the same code.
    return _db.runTransaction<String>((tx) async {
      final counter = await tx.get(counterRef);
      final lastId = counter.exists ? asInt(counter.data()?['lastId']) : 0;
      final nextId = lastId + 1;
      final code = Client.codeFor(nextId);

      tx.set(counterRef, {'lastId': nextId});
      tx.set(_clients.doc(code), ClientMapper.toCreateMap(draft, code: code));
      return code;
    });
  }

  @override
  Future<void> updateBasicInfo(String clientId, ClientBasicInfo info) {
    return _clients.doc(clientId).update(ClientMapper.basicInfoToMap(info));
  }

  @override
  Future<void> updateFileInfo(String clientId, ClientFileInfo info) {
    return _clients.doc(clientId).update(ClientMapper.fileInfoToMap(info));
  }

  @override
  Future<void> updatePaymentInfo(String clientId, ClientPaymentInfo info) {
    return _clients.doc(clientId).update(ClientMapper.paymentInfoToMap(info));
  }

  @override
  Future<void> setActive(String clientId, bool active) {
    return _clients.doc(clientId).update(ClientMapper.activeToMap(active));
  }

  @override
  Future<void> markFullyPaid(String clientId) {
    return _clients
        .doc(clientId)
        .update(ClientMapper.paymentStatusToMap(Client.fullyPaidStatus));
  }

  @override
  Stream<ClientCart?> watchCart(String clientId) {
    return _cartRef(clientId).snapshots().map(
      (doc) => doc.exists ? ClientCartMapper.fromMap(doc.data() ?? const {}) : null,
    );
  }

  @override
  Future<void> addToCart(String clientId, List<CartLine> additions) {
    final clientRef = _clients.doc(clientId);
    final cartRef = _cartRef(clientId);

    return _db.runTransaction<void>((tx) async {
      final snapshot = await tx.get(cartRef);
      final current = snapshot.exists
          ? ClientCartMapper.fromMap(snapshot.data() ?? const {})
          : ClientCart.empty;

      final updated = current.merge(additions);

      tx.set(cartRef, ClientCartMapper.toMap(updated), SetOptions(merge: true));
      tx.update(clientRef, ClientMapper.totalAmountToMap(updated.totalAmount));
    });
  }

  @override
  Future<void> changeCartQuantity(String clientId, String docItemId, int delta) {
    final clientRef = _clients.doc(clientId);
    final cartRef = _cartRef(clientId);

    return _db.runTransaction<void>((tx) async {
      final snapshot = await tx.get(cartRef);
      if (!snapshot.exists) return;

      final updated = ClientCartMapper.fromMap(
        snapshot.data() ?? const {},
      ).adjustQuantity(docItemId, delta);
      if (updated == null) return;

      tx.update(cartRef, ClientCartMapper.toMap(updated));
      tx.update(clientRef, ClientMapper.totalAmountToMap(updated.totalAmount));
    });
  }
}
