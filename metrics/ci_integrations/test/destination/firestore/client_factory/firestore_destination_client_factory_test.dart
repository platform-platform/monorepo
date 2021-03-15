// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:ci_integration/destination/firestore/adapter/firestore_destination_client_adapter.dart';
import 'package:ci_integration/destination/firestore/client_factory/firestore_destination_client_factory.dart';
import 'package:firedart/firedart.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../../test_utils/matchers.dart';
import '../test_utils/test_data/firestore_config_test_data.dart';

void main() {
  group("FirestoreDestinationClientFactory", () {
    final firestoreConfig = FirestoreConfigTestData.firestoreDestiantionConfig;
    final email = firestoreConfig.firebaseUserEmail;
    final password = firestoreConfig.firebaseUserPassword;

    final _firebaseAuthMock = _FirebaseAuthMock();
    final firestoreClientFactory =
        FirestoreDestinationClientFactory(_firebaseAuthMock);

    FirestoreDestinationClientAdapter adapter;

    tearDown(() {
      adapter?.dispose();
      reset(_firebaseAuthMock);
    });

    test(
      ".create() throws an ArgumentError if the given FirestoreConfig is null",
      () {
        expect(
          () => firestoreClientFactory.create(null),
          throwsArgumentError,
        );
      },
    );

    test(".create() throws if authentication is failed", () {
      when(_firebaseAuthMock.signIn(email, password)).thenThrow(Exception());

      final result = firestoreClientFactory.create(firestoreConfig);

      expect(result, throwsA(anything));
    });

    test(".create() authenticates Firestore with the given config", () async {
      final user = User.fromMap({});
      when(_firebaseAuthMock.signIn(email, password)).thenAnswer(
        (_) => Future.value(user),
      );

      adapter = await firestoreClientFactory.create(firestoreConfig);

      verify(_firebaseAuthMock.signIn(email, password)).called(once);
    });

    test(
      ".create() creates a FirestoreDestinationClientAdapter instance from the given FirestoreConfig",
      () async {
        final user = User.fromMap({});
        when(_firebaseAuthMock.signIn(any, any)).thenAnswer(
          (_) => Future.value(user),
        );

        adapter = await firestoreClientFactory.create(firestoreConfig);

        expect(adapter, isA<FirestoreDestinationClientAdapter>());
      },
    );
  });
}

class _FirebaseAuthMock extends Mock implements FirebaseAuth {}
