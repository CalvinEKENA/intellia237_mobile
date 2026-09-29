import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/app/router/app_router.dart';
import 'package:intellia237/app/router/app_routes.dart';
import 'package:intellia237/features/auth/application/auth_controller.dart';
import 'package:intellia237/features/auth/application/auth_state.dart';
import 'package:intellia237/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:intellia237/features/auth/domain/app_role.dart';
import 'package:intellia237/features/auth/domain/auth_entry_intent.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Un ancien compte enseignant de test, converti en élève Terminale D par
/// `functions/scripts/provisionStudent.ts --convert-role teacher:student`,
/// se connecte par e-mail (Yahoo) et mot de passe à la porte publique.
///
/// Les documents reproduisent exactement ce qu'écrit la conversion
/// (`functions/src/services/studentRoleMigration.ts`) : rôle élève sans
/// rôle additionnel, compte actif, profil élève Terminale D, profil
/// enseignant archivé, établissement retiré. Le vrai dépôt d'authentification
/// les lit ; seul Firebase est simulé.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('connexion e-mail publique : l’espace élève s’ouvre directement, '
      'sans bouclier du personnel ni choix d’espace', () async {
    final container = _container(_migratedAccount());
    final adoption = await container
        .read(authControllerProvider.notifier)
        .signInWithEmail(email: _email, password: 'test-only');

    expect(adoption, isA<AuthEntryAdopted>());
    final auth = container.read(authControllerProvider);
    expect(auth.status, AuthStatus.authenticated);
    expect(auth.error, isNull);
    expect(auth.role, AppRole.student);
    expect(auth.availableRoles, [AppRole.student]);
    expect(auth.availableRoles, isNot(contains(AppRole.teacher)));
    expect(auth.spaceChoicePending, isFalse);
    expect(auth.profileCompleted, isTrue);
    expect(_redirect(auth, AppRoutes.emailLogin), AppRoutes.studentHome);
  });

  test('redémarrage : la même session rouvre l’espace élève', () async {
    final account = _migratedAccount()..signedIn = true;
    final container = _container(account);
    await container.read(authControllerProvider.notifier).completeBootstrap();

    final auth = container.read(authControllerProvider);
    expect(auth.status, AuthStatus.authenticated);
    expect(auth.role, AppRole.student);
    expect(_redirect(auth, AppRoutes.bootstrap), AppRoutes.studentHome);
  });

  test('si l’ancien profil n’était pas complet, l’élève complète son '
      'inscription d’élève — jamais le bouclier du personnel', () async {
    final container = _container(_migratedAccount(profileCompleted: false));
    await container
        .read(authControllerProvider.notifier)
        .signInWithEmail(email: _email, password: 'test-only');

    final auth = container.read(authControllerProvider);
    expect(auth.error, isNull);
    expect(auth.role, AppRole.student);
    expect(
      _redirect(auth, AppRoutes.emailLogin),
      AppRoutes.studentRegistration,
    );
  });
}

const _email = 'eleve.test@yahoo.fr';
const _uid = 'migrated-student';

_Account _migratedAccount({bool profileCompleted = true}) => _Account({
  'users/$_uid': {
    'uid': _uid,
    'email': _email,
    'firstName': 'Test',
    'lastName': 'Eleve',
    'role': 'student',
    'roles': <String>[],
    'classLevel': 'terminale',
    'series': 'D',
    'accountStatus': 'active',
    'requiresValidation': false,
    'profileCompleted': profileCompleted,
  },
  'student_profiles/$_uid': {
    'uid': _uid,
    'firstName': 'Test',
    'lastName': 'Eleve',
    'classLevel': 'Terminale',
    'series': 'D',
    'profileCompleted': profileCompleted,
    'preferences': {
      'academicLevelId': 'fr_general_terminale',
      'streamOrSpeciality': 'D',
    },
  },
  'teacher_profiles/$_uid': {'archived': true, 'subject': 'Anglais'},
});

ProviderContainer _container(_Account account) {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(
        AuthRepositoryImpl(
          auth: _Auth(account),
          firestore: _Firestore(account),
        ),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

String? _redirect(AuthState auth, String location) => resolveAppRedirect(
  auth: auth,
  hasSeenOnboarding: true,
  hasAuthenticatedBefore: true,
  location: location,
);

/// Le compte côté Firebase : l'identité e-mail et ses documents.
class _Account {
  _Account(this.documents);

  final Map<String, Map<String, dynamic>> documents;
  bool signedIn = false;
}

class _Auth extends Fake implements FirebaseAuth {
  _Auth(this.account);

  final _Account account;

  @override
  User? get currentUser => account.signedIn ? _User() : null;

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (email.trim() != _email) {
      throw FirebaseAuthException(code: 'invalid-credential');
    }
    account.signedIn = true;
    return _Credential();
  }

  @override
  Future<void> signOut() async => account.signedIn = false;
}

class _Credential extends Fake implements UserCredential {
  @override
  User get user => _User();
}

class _User extends Fake implements User {
  @override
  String get uid => _uid;

  @override
  String get email => _email;

  @override
  List<UserInfo> get providerData => const [];
}

class _Firestore extends Fake implements FirebaseFirestore {
  _Firestore(this.account);

  final _Account account;

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _Collection(account, path);
}

// Doublure de test : Firestore marque ces types comme scellés, sans
// fournir d'implémentation de test.
// ignore: subtype_of_sealed_class
class _Collection extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  _Collection(this.account, this.path);

  final _Account account;

  @override
  final String path;

  @override
  DocumentReference<Map<String, dynamic>> doc([String? id]) =>
      _Document(account, '$path/$id');
}

// Doublure de test : Firestore marque ces types comme scellés, sans
// fournir d'implémentation de test.
// ignore: subtype_of_sealed_class
class _Document extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  _Document(this.account, this.path);

  final _Account account;

  @override
  final String path;

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([
    GetOptions? options,
  ]) async => _Snapshot(account.documents[path]);
}

// Doublure de test : Firestore marque ces types comme scellés, sans
// fournir d'implémentation de test.
// ignore: subtype_of_sealed_class
class _Snapshot extends Fake implements DocumentSnapshot<Map<String, dynamic>> {
  _Snapshot(this._data);

  final Map<String, dynamic>? _data;

  @override
  bool get exists => _data != null;

  @override
  Map<String, dynamic>? data() => _data;
}
