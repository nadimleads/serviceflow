import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:serviceflow/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:serviceflow/features/auth/data/repositories/firestore_user_profile_repository.dart';
import 'package:serviceflow/features/auth/domain/repositories/auth_repository.dart';
import 'package:serviceflow/features/auth/domain/repositories/user_profile_repository.dart';
import 'package:serviceflow/features/auth/domain/usecases/resolve_session.dart';
import 'package:serviceflow/features/auth/domain/usecases/sign_in.dart';
import 'package:serviceflow/features/auth/domain/usecases/sign_out.dart';
import 'package:serviceflow/features/auth/domain/usecases/watch_auth_state.dart';
import 'package:serviceflow/features/catalogue/data/repositories/firestore_doc_item_repository.dart';
import 'package:serviceflow/features/catalogue/domain/repositories/doc_item_repository.dart';
import 'package:serviceflow/features/catalogue/domain/usecases/create_doc_item.dart';
import 'package:serviceflow/features/catalogue/domain/usecases/set_doc_item_availability.dart';
import 'package:serviceflow/features/catalogue/domain/usecases/update_doc_item.dart';
import 'package:serviceflow/features/catalogue/domain/usecases/watch_available_doc_items.dart';
import 'package:serviceflow/features/catalogue/domain/usecases/watch_doc_items.dart';
import 'package:serviceflow/features/clients/data/repositories/firestore_client_repository.dart';
import 'package:serviceflow/features/clients/domain/repositories/client_repository.dart';
import 'package:serviceflow/features/clients/domain/usecases/add_docs_to_client_cart.dart';
import 'package:serviceflow/features/clients/domain/usecases/change_cart_doc_quantity.dart';
import 'package:serviceflow/features/clients/domain/usecases/create_client.dart';
import 'package:serviceflow/features/clients/domain/usecases/mark_client_fully_paid.dart';
import 'package:serviceflow/features/clients/domain/usecases/set_client_active.dart';
import 'package:serviceflow/features/clients/domain/usecases/update_client_basic_info.dart';
import 'package:serviceflow/features/clients/domain/usecases/update_client_file_info.dart';
import 'package:serviceflow/features/clients/domain/usecases/update_client_payment_info.dart';
import 'package:serviceflow/features/clients/domain/usecases/watch_client.dart';
import 'package:serviceflow/features/clients/domain/usecases/watch_client_cart.dart';
import 'package:serviceflow/features/clients/domain/usecases/watch_clients.dart';

/// The composition root.
///
/// This is the one file that knows both the domain interfaces and the concrete
/// Firebase implementations behind them. Presentation code only ever sees use
/// cases, read with `context.read<SomeUseCase>()`. It is never handed a
/// repository and it never imports anything under a feature's `data/` folder.
///
/// [buildProviders] takes the repositories as interfaces so a widget test can
/// hand it fakes. [buildFirebaseProviders] is the production wiring.
List<SingleChildWidget> buildProviders({
  required AuthRepository auth,
  required UserProfileRepository userProfiles,
  required ClientRepository clients,
  required DocItemRepository docItems,
}) {
  return [
    // Auth
    Provider(create: (_) => SignIn(auth)),
    Provider(create: (_) => SignOut(auth)),
    Provider(create: (_) => WatchAuthState(auth)),
    Provider(create: (_) => ResolveSession(userProfiles)),

    // Clients
    Provider(create: (_) => WatchClients(clients)),
    Provider(create: (_) => WatchClient(clients)),
    Provider(create: (_) => CreateClient(clients)),
    Provider(create: (_) => UpdateClientBasicInfo(clients)),
    Provider(create: (_) => UpdateClientFileInfo(clients)),
    Provider(create: (_) => UpdateClientPaymentInfo(clients)),
    Provider(create: (_) => SetClientActive(clients)),
    Provider(create: (_) => MarkClientFullyPaid(clients)),
    Provider(create: (_) => WatchClientCart(clients)),
    Provider(create: (_) => AddDocsToClientCart(clients)),
    Provider(create: (_) => ChangeCartDocQuantity(clients)),

    // Catalogue
    Provider(create: (_) => WatchDocItems(docItems)),
    Provider(create: (_) => WatchAvailableDocItems(docItems)),
    Provider(create: (_) => CreateDocItem(docItems)),
    Provider(create: (_) => UpdateDocItem(docItems)),
    Provider(create: (_) => SetDocItemAvailability(docItems)),
  ];
}

/// Production wiring: every repository backed by the live Firebase project.
List<SingleChildWidget> buildFirebaseProviders() {
  final firestore = FirebaseFirestore.instance;
  return buildProviders(
    auth: FirebaseAuthRepository(FirebaseAuth.instance),
    userProfiles: FirestoreUserProfileRepository(firestore),
    clients: FirestoreClientRepository(firestore),
    docItems: FirestoreDocItemRepository(firestore),
  );
}
