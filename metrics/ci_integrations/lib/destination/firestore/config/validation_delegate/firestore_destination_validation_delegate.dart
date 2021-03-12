// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:ci_integration/client/firestore/firestore.dart' as fs;
import 'package:ci_integration/client/firestore/mappers/firebase_auth_exception_code_mapper.dart';
import 'package:ci_integration/client/firestore/model/firebase_auth_exception_code.dart';
import 'package:ci_integration/destination/firestore/config/factory/firebase_auth_factory.dart';
import 'package:ci_integration/destination/firestore/config/factory/firestore_factory.dart';
import 'package:ci_integration/integration/interface/base/config/validation_delegate/validation_delegate.dart';
import 'package:ci_integration/util/model/interaction_result.dart';
import 'package:firedart/firedart.dart';

/// A [ValidationDelegate] for the Firestore destination integration.
class FirestoreDestinationValidationDelegate implements ValidationDelegate {
  /// Creates a new instance of the [FirestoreDestinationValidationDelegate].
  FirestoreDestinationValidationDelegate();

  /// Validates the given [apiKey].
  Future<InteractionResult<void>> validatePublicApiKey(
    FirebaseAuthFactory authFactory,
    String firebaseApiKey,
  ) async {
    try {
      authFactory.create(firebaseApiKey);
    } on FirebaseAuthException catch (e) {
      final exceptionCode = e.code;

      const mapper = FirebaseAuthExceptionCodeMapper();
      final code = mapper.map(exceptionCode);

      if (code == FirebaseAuthExceptionCode.invalidApiKey) {
        return const InteractionResult.error(
          message: 'The Firebase API key is not valid.',
        );
      }
    }

    return const InteractionResult.success();
  }

  /// Validates the given [email] and [password].
  Future<InteractionResult<void>> validateAuth(
    FirebaseAuthFactory authFactory,
    String firebaseApiKey,
    String email,
    String password,
  ) async {
    try {
      authFactory.createAndAuthenticate(
        firebaseApiKey,
        email,
        password,
      );
    } on FirebaseAuthException catch (e) {
      final exceptionCode = e.code;

      const mapper = FirebaseAuthExceptionCodeMapper();
      final code = mapper.map(exceptionCode);

      if (code == FirebaseAuthExceptionCode.emailNotFound) {
        return const InteractionResult.error(
          message: 'The email is not found.',
        );
      } else if (code == FirebaseAuthExceptionCode.invalidPassword) {
        return const InteractionResult.error(
          message: 'The password is not valid.',
        );
      } else if (code == FirebaseAuthExceptionCode.passwordLoginDisabled) {
        return const InteractionResult.error(
          message: 'The login via password is disabled.',
        );
      }
    }

    return const InteractionResult.success();
  }

  /// Validates the given [firebaseProjectId].
  Future<InteractionResult<void>> validateFirebaseProjectId(
    String firebaseProjectId,
  ) async {
    return const InteractionResult.success();
  }

  /// Validates the given [metricsProjectId].
  Future<InteractionResult<void>> validateMetricsProjectId(
    String metricsProjectId,
  ) async {
    return const InteractionResult.success();
  }
}
