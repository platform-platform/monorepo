// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:ci_integration/client/firestore/firestore.dart' as fs;
import 'package:ci_integration/client/firestore/mappers/firebase_auth_exception_code_mapper.dart';
import 'package:ci_integration/client/firestore/model/firebase_auth_exception_code.dart';
import 'package:ci_integration/integration/interface/base/config/validation_delegate/validation_delegate.dart';
import 'package:ci_integration/util/model/interaction_result.dart';
import 'package:firedart/firedart.dart';
import 'package:firedart/src/auth/exception/firebase_auth_exception.dart';

/// A [ValidationDelegate] for the Firestore destination integration.
class FirestoreDestinationValidationDelegate implements ValidationDelegate {
  /// A [FirebaseAuth] instance to work with the Firebase Auth services.
  final FirebaseAuth _firebaseAuth;

  /// A [Firestore] client to work with the Cloud Firestore services.
  final fs.Firestore _firestore;

  /// Creates an instance of the [FirestoreDestinationValidationDelegate].
  ///
  /// Throws an [ArgumentError] if the given [fs.Firestore] or [_firebaseAuth]
  /// are `null`.
  FirestoreDestinationValidationDelegate(this._firestore, this._firebaseAuth) {
    ArgumentError.checkNotNull(_firestore);
    ArgumentError.checkNotNull(_firebaseAuth);
  }

  /// Validates the given [apiKey].
  Future<InteractionResult<void>> validatePublicApiKey(String apiKey) async {
    try {
      await _firebaseAuth.signIn('email@email.com', '123456');

      return const InteractionResult.success();
    } on FirebaseAuthException catch (e) {
      final exceptionCode = e.code;

      const mapper = FirebaseAuthExceptionCodeMapper();
      final code = mapper.map(exceptionCode);

      if (code == FirebaseAuthExceptionCode.invalidApiKey) {
        return const InteractionResult.error();
      }

      return const InteractionResult.success();
    }
  }

  /// Validates the given [email] and [password].
  Future<InteractionResult<void>> validateAuth(
    String apiKey,
    String email,
    String password,
  ) async {
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
