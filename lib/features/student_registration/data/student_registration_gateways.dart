import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/registration_diagnostic.dart';

abstract interface class RegistrationAuthUser {
  String get uid;
  String? get email;
  String? get phoneNumber;
  bool get emailVerified;

  /// Session ouverte par un jeton serveur (code d'accès élève) : ni
  /// téléphone ni e-mail, mais une identité vérifiée par le serveur.
  bool get openedByServerToken;

  /// Identité ouverte avec Google : vérifiée par Google, sans mot de passe.
  bool get signedInWithGoogle;

  Future<void> delete();
  Future<void> sendEmailVerification();
  Future<void> updateDisplayName(String displayName);
}

abstract interface class RegistrationAuthGateway {
  RegistrationAuthUser? get currentUser;

  Future<RegistrationAuthUser?> createUser({
    required String email,
    required String password,
  });

  Future<RegistrationAuthUser?> signIn({
    required String email,
    required String password,
  });
}

class RegistrationAuthFailure implements Exception {
  const RegistrationAuthFailure({required this.code, this.technicalMessage});

  final String code;
  final String? technicalMessage;
}

abstract interface class RegistrationDocumentStore {
  Future<RegistrationOperation> upsertUser({
    required String uid,
    required Map<String, dynamic> createData,
    required Map<String, dynamic> updateData,
  });

  Future<RegistrationOperation> upsertProfile({
    required String uid,
    required Map<String, dynamic> createData,
    required Map<String, dynamic> updateData,
  });
}

class RegistrationWriteFailure implements Exception {
  const RegistrationWriteFailure({
    required this.operation,
    required this.code,
    this.technicalMessage,
  });

  final RegistrationOperation operation;
  final String code;
  final String? technicalMessage;
}

class FirebaseRegistrationAuthGateway implements RegistrationAuthGateway {
  FirebaseRegistrationAuthGateway(this._auth);

  final FirebaseAuth _auth;

  @override
  RegistrationAuthUser? get currentUser {
    final user = _auth.currentUser;
    return user == null ? null : FirebaseRegistrationAuthUser(user);
  }

  @override
  Future<RegistrationAuthUser?> createUser({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password)
          .timeout(const Duration(seconds: 20));
      final user = credential.user;
      return user == null ? null : FirebaseRegistrationAuthUser(user);
    } on FirebaseAuthException catch (error) {
      throw RegistrationAuthFailure(
        code: error.code,
        technicalMessage: error.message,
      );
    }
  }

  @override
  Future<RegistrationAuthUser?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth
          .signInWithEmailAndPassword(email: email, password: password)
          .timeout(const Duration(seconds: 20));
      final user = credential.user;
      return user == null ? null : FirebaseRegistrationAuthUser(user);
    } on FirebaseAuthException catch (error) {
      throw RegistrationAuthFailure(
        code: error.code,
        technicalMessage: error.message,
      );
    }
  }
}

class FirebaseRegistrationAuthUser implements RegistrationAuthUser {
  FirebaseRegistrationAuthUser(this._user);

  final User _user;

  @override
  String get uid => _user.uid;

  @override
  String? get email => _user.email;

  @override
  String? get phoneNumber => _user.phoneNumber;

  @override
  bool get emailVerified => _user.emailVerified;

  @override
  bool get openedByServerToken =>
      _user.providerData.isEmpty &&
      (_user.email?.isEmpty ?? true) &&
      (_user.phoneNumber?.isEmpty ?? true);

  @override
  bool get signedInWithGoogle =>
      _user.providerData.any((info) => info.providerId == 'google.com');

  @override
  Future<void> delete() => _user.delete();

  @override
  Future<void> sendEmailVerification() => _user.sendEmailVerification();

  @override
  Future<void> updateDisplayName(String displayName) =>
      _user.updateDisplayName(displayName);
}

class FirebaseRegistrationDocumentStore implements RegistrationDocumentStore {
  FirebaseRegistrationDocumentStore(this._firestore);

  final FirebaseFirestore _firestore;

  static const _usersCollection = 'users';
  static const _profilesCollection = 'student_profiles';

  @override
  Future<RegistrationOperation> upsertUser({
    required String uid,
    required Map<String, dynamic> createData,
    required Map<String, dynamic> updateData,
  }) {
    return _upsert(
      reference: _firestore.collection(_usersCollection).doc(uid),
      createData: createData,
      updateData: updateData,
      createOperation: RegistrationOperation.userDocumentCreate,
      updateOperation: RegistrationOperation.userDocumentUpdate,
    );
  }

  @override
  Future<RegistrationOperation> upsertProfile({
    required String uid,
    required Map<String, dynamic> createData,
    required Map<String, dynamic> updateData,
  }) {
    return _upsert(
      reference: _firestore.collection(_profilesCollection).doc(uid),
      createData: createData,
      updateData: updateData,
      createOperation: RegistrationOperation.profileCreate,
      updateOperation: RegistrationOperation.profileUpdate,
    );
  }

  Future<RegistrationOperation> _upsert({
    required DocumentReference<Map<String, dynamic>> reference,
    required Map<String, dynamic> createData,
    required Map<String, dynamic> updateData,
    required RegistrationOperation createOperation,
    required RegistrationOperation updateOperation,
  }) async {
    var operation = createOperation;
    try {
      await _firestore
          .runTransaction<void>((transaction) async {
            final snapshot = await transaction.get(reference);
            operation = snapshot.exists ? updateOperation : createOperation;
            if (snapshot.exists) {
              transaction.update(reference, updateData);
            } else {
              transaction.set(reference, createData);
            }
          })
          .timeout(const Duration(seconds: 20));
      return operation;
    } on FirebaseException catch (error) {
      throw RegistrationWriteFailure(
        operation: operation,
        code: error.code,
        technicalMessage: error.message,
      );
    }
  }
}
