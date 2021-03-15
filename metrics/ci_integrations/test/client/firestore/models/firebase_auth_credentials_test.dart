// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:ci_integration/client/firestore/models/firebase_auth_credentials.dart';
import 'package:test/test.dart';

void main() {
  group("FirebaseAuthCredentials", () {
    const apiKey = 'key';
    const email = 'email';
    const password = 'password';

    test(
      "throws an ArgumentError if the given api key is null",
      () {
        expect(
          () => FirebaseAuthCredentials(
            apiKey: null,
            email: email,
            password: password,
          ),
          throwsArgumentError,
        );
      },
    );

    test(
      "throws an ArgumentError if the given email is null",
      () {
        expect(
          () => FirebaseAuthCredentials(
            apiKey: apiKey,
            email: null,
            password: password,
          ),
          throwsArgumentError,
        );
      },
    );

    test(
      "throws an ArgumentError if the given password is null",
      () {
        expect(
          () => FirebaseAuthCredentials(
            apiKey: apiKey,
            email: email,
            password: null,
          ),
          throwsArgumentError,
        );
      },
    );

    test(
      "creates an instance with the given parameters",
      () {
        final credentials = FirebaseAuthCredentials(
          apiKey: apiKey,
          email: email,
          password: password,
        );

        expect(credentials.apiKey, equals(apiKey));
        expect(credentials.email, equals(email));
        expect(credentials.password, equals(password));
      },
    );
  });
}
