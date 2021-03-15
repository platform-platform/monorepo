// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:ci_integration/client/firestore/models/firestore_exception_reason.dart';
import 'package:ci_integration/integration/interface/base/client/mapper/mapper.dart';

/// A class that provides methods for mapping [FirestoreExceptionReason]s.
class FirestoreExceptionReasonMapper
    implements Mapper<String, FirestoreExceptionReason> {
  /// An exception reason indicating that the provided Firebase project identifier
  /// is not valid or project with such identifier does not exist.
  static const String consumerInvalid = 'CONSUMER_INVALID';

  /// An exception reason indicating that the provided Firebase project with the
  /// given project ID is not found.
  static const String notFound = 'NOT_FOUND';

  /// An exception reason indicating that the provided Firebase project is
  /// deleted.
  static const String projectDeleted = 'PROJECT_DELETED';

  /// An exception reason indicating that the provided Firebase project is
  /// deleted.
  static const String projectInvalid = 'PROJECT_INVALID';

  /// Creates a new instance of the [FirestoreExceptionReasonMapper].
  const FirestoreExceptionReasonMapper();

  @override
  FirestoreExceptionReason map(String value) {
    switch (value) {
      case consumerInvalid:
        return FirestoreExceptionReason.consumerInvalid;
      case notFound:
        return FirestoreExceptionReason.notFound;
      case projectDeleted:
        return FirestoreExceptionReason.projectDeleted;
      case projectInvalid:
        return FirestoreExceptionReason.projectInvalid;
      default:
        return null;
    }
  }

  @override
  String unmap(FirestoreExceptionReason value) {
    switch (value) {
      case FirestoreExceptionReason.consumerInvalid:
        return consumerInvalid;
      case FirestoreExceptionReason.notFound:
        return notFound;
      case FirestoreExceptionReason.projectDeleted:
        return projectDeleted;
      case FirestoreExceptionReason.projectInvalid:
        return projectInvalid;
    }
    return null;
  }
}
