// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:ci_integration/client/firestore/mappers/firestore_exception_reason_mapper.dart';
import 'package:ci_integration/client/firestore/models/firebase_auth_credentials.dart';
import 'package:ci_integration/client/firestore/models/firestore_exception_reason.dart';
import 'package:ci_integration/destination/firestore/config/factory/firebase_auth_factory.dart';
import 'package:ci_integration/destination/firestore/config/factory/firestore_factory.dart';
import 'package:ci_integration/destination/firestore/strings/firestore_strings.dart';
import 'package:ci_integration/integration/interface/base/config/validation_delegate/validation_delegate.dart';
import 'package:ci_integration/integration/validation/model/field_validation_result.dart';
import 'package:firedart/firedart.dart';
import 'package:ci_integration/client/firestore/firestore.dart' as fs;

/// A [ValidationDelegate] for the Firestore destination integration.
class FirestoreDestinationValidationDelegate implements ValidationDelegate {
  /// A [FirestoreExceptionReasonMapper] needed for mapping
  /// [FirestoreExceptionReason]s.
  static const FirestoreExceptionReasonMapper reasonMapper =
      FirestoreExceptionReasonMapper();

  /// A [FirebaseAuthFactory] this delegate uses to create [FirebaseAuth]
  /// instances.
  final FirebaseAuthFactory authFactory;

  /// A [FirebaseAuthFactory] this delegate uses to create [Firestore]
  /// instances.
  final FirestoreFactory firestoreFactory;

  /// Creates a new instance of the [FirestoreDestinationValidationDelegate]
  /// with the given [authFactory].
  FirestoreDestinationValidationDelegate(
    this.authFactory,
    this.firestoreFactory,
  ) {
    ArgumentError.checkNotNull(authFactory, 'authFactory');
    ArgumentError.checkNotNull(firestoreFactory, 'firestoreFactory');
  }

  /// Validates the given [firebaseApiKey].
  Future<FieldValidationResult> validatePublicApiKey(
    String firebaseApiKey,
  ) async {
    try {
      final auth = authFactory.create(firebaseApiKey);

      await auth.signIn('stub@email.com', 'stub_password');
    } on FirebaseAuthException catch (e) {
      final exceptionCode = e.code;

      if (exceptionCode == FirebaseAuthExceptionCode.invalidApiKey) {
        return const FieldValidationResult.failure(
          FirestoreStrings.apiKeyInvalid,
        );
      }
    }

    return const FieldValidationResult.success();
  }

  /// Validates the given Firebase authentication [credentials].
  Future<FieldValidationResult> validateAuth(
    FirebaseAuthCredentials credentials,
  ) async {
    try {
      await _createAuth(credentials);
    } on FirebaseAuthException catch (e) {
      final exceptionCode = e.code;

      const invalidAuthExceptionCodes = [
        FirebaseAuthExceptionCode.emailNotFound,
        FirebaseAuthExceptionCode.invalidPassword,
        FirebaseAuthExceptionCode.passwordLoginDisabled,
      ];

      if (invalidAuthExceptionCodes.contains(exceptionCode)) {
        final message = e.message;

        return FieldValidationResult.failure(message);
      }
    }

    return const FieldValidationResult.success();
  }

  /// Validates the given [firebaseProjectId].
  Future<FieldValidationResult> validateFirebaseProjectId(
    FirebaseAuthCredentials credentials,
    String firebaseProjectId,
  ) async {
    try {
      final firestore = await _createFirestore(
        credentials,
        firebaseProjectId,
      );

      await firestore.collection('stub_collection').getDocuments();
    } on FirestoreException catch (e) {
      final reasons = e.reasons;

      final exceptionReasons = reasons.map(
        (reason) => reasonMapper.map(reason),
      );

      const invalidFirebaseProjectIdReasons = [
        FirestoreExceptionReason.notFound,
        FirestoreExceptionReason.consumerInvalid,
        FirestoreExceptionReason.projectInvalid,
        FirestoreExceptionReason.projectDeleted,
      ];

      final containsInvalidFirebaseProjectIdReason = exceptionReasons.any(
        (reason) => invalidFirebaseProjectIdReasons.contains(reason),
      );
      if (containsInvalidFirebaseProjectIdReason) {
        return const FieldValidationResult.failure(
          FirestoreStrings.projectIdInvalid,
        );
      }
    }

    return const FieldValidationResult.success();
  }

  /// Validates the given [metricsProjectId].
  Future<FieldValidationResult> validateMetricsProjectId(
    FirebaseAuthCredentials credentials,
    String firebaseProjectId,
    String metricsProjectId,
  ) async {
    try {
      final firestore = await _createFirestore(
        credentials,
        firebaseProjectId,
      );

      final metricsProject = await firestore
          .collection('projects')
          .document(metricsProjectId)
          .get();

      if (!metricsProject.exists) {
        return const FieldValidationResult.failure(
          FirestoreStrings.metricsProjectIdDoesNotExist,
        );
      }
    } on FirestoreException catch (e) {
      final exceptionCode = '${e.code}';
      final exceptionMessage = e.message;

      return FieldValidationResult.unknown(
        FirestoreStrings.metricsProjectIdValidationFailedMessage(
          exceptionCode,
          exceptionMessage,
        ),
      );
    }

    return const FieldValidationResult.success();
  }

  /// Creates a new instance of the [Firestore] using the given [credentials]
  /// and the [firebaseProjectId].
  Future<fs.Firestore> _createFirestore(
    FirebaseAuthCredentials credentials,
    String firebaseProjectId,
  ) async {
    final auth = await _createAuth(credentials);

    return firestoreFactory.create(firebaseProjectId, auth);
  }

  /// Creates a new authenticated [FirebaseAuth] using the given [credentials].
  Future<FirebaseAuth> _createAuth(FirebaseAuthCredentials credentials) async {
    final auth = authFactory.create(credentials.apiKey);

    await auth.signIn(credentials.email, credentials.password);

    return auth;
  }
}
