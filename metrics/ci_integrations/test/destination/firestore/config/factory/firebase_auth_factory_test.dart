// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:ci_integration/destination/firestore/config/factory/firebase_auth_factory.dart';
import 'package:test/test.dart';

void main() {
  group("FirebaseAuthFactory", () {
    const apiKey = 'api';
    const authFactory = FirebaseAuthFactory();

    test(
      ".create() throws an ArgumentError if the given firebase api key is null",
      () {
        expect(() => authFactory.create(null), throwsArgumentError);
      },
    );

    test(
      ".create() returns a new firebase auth instance with the given api key",
      () {
        final auth = authFactory.create(apiKey);

        expect(auth.apiKey, equals(apiKey));
      },
    );
  });
}
