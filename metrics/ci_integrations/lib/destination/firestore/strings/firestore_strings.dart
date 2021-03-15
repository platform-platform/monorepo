// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

// ignore_for_file: public_member_api_docs

/// Holds the strings used across the Firestore destination integration.
class FirestoreStrings {
  static const String apiKeyInvalid = 'The Firebase API key is invalid.';
  static const String projectIdInvalid =
      'The given Firebase project id is invalid';
  static const String metricsProjectIdDoesNotExist =
      'The given metrics project is does not exist.';
  static String metricsProjectIdValidationFailedMessage(
    String code,
    String message,
  ) {
    return "Cannot validate the given Metrics project ID. The validation has "
        "failed with the following exception code: $code and message: '$message'."
        " Please check your security rules or try again later.";
  }
}
