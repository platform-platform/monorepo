// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:ci_integration/client/firestore/models/firebase_auth_credentials.dart';
import 'package:ci_integration/destination/firestore/config/factory/firebase_auth_factory.dart';
import 'package:ci_integration/destination/firestore/config/factory/firestore_factory.dart';
import 'package:ci_integration/destination/firestore/config/validation_delegate/firestore_destination_validation_delegate.dart';
import 'package:ci_integration/destination/firestore/strings/firestore_strings.dart';
import 'package:ci_integration/source/jenkins/strings/jenkins_strings.dart';
import 'package:firedart/firedart.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

void main() {
  group("FirestoreDestinationValidationDelegate", () {
    const apiKey = 'key';
    const email = 'stub@email.com';
    const password = 'stub_password';
    const message = 'message';
    final credentials = FirebaseAuthCredentials(
      apiKey: apiKey,
      email: email,
      password: password,
    );

    final user = User.fromMap(const {});

    final authFactory = _FirebaseAuthFactoryMock();
    final firestoreFactory = _FirestoreFactoryMock();
    final firebaseAuth = _FirebaseAuthMock();

    final delegate = FirestoreDestinationValidationDelegate(
      authFactory,
      firestoreFactory,
    );

    PostExpectation<FirebaseAuth> whenCreateFirebaseAuth() {
      return when(authFactory.create(apiKey));
    }

    PostExpectation<Future<User>> whenSignIn() {
      return when(firebaseAuth.signIn(email, password));
    }

    tearDown(() {
      reset(authFactory);
      reset(firestoreFactory);
      reset(firebaseAuth);
    });

    test(
      "throws an ArgumentError if the given auth factory is null",
      () {
        expect(
          () => FirestoreDestinationValidationDelegate(
            null,
            firestoreFactory,
          ),
          throwsArgumentError,
        );
      },
    );

    test(
      "throws an ArgumentError if the given firestore factory is null",
      () {
        expect(
          () => FirestoreDestinationValidationDelegate(
            authFactory,
            null,
          ),
          throwsArgumentError,
        );
      },
    );

    test(
      "creates an instance with the given parameters",
      () {
        final validationDelegate = FirestoreDestinationValidationDelegate(
          authFactory,
          firestoreFactory,
        );

        expect(validationDelegate.authFactory, equals(authFactory));
        expect(validationDelegate.firestoreFactory, equals(firestoreFactory));
      },
    );

    test(
      ".validatePublicApiKey() creates a firebase auth with the firebase auth factory",
      () {
        whenCreateFirebaseAuth().thenReturn(firebaseAuth);

        delegate.validatePublicApiKey(apiKey);

        verify(authFactory.create(apiKey)).called(1);
      },
    );

    test(
      ".validatePublicApiKey() signs in with the created firebase auth",
      () {
        whenCreateFirebaseAuth().thenReturn(firebaseAuth);

        delegate.validatePublicApiKey(apiKey);

        verify(firebaseAuth.signIn(any, any)).called(1);
      },
    );

    test(
      ".validatePublicApiKey() returns a failure field validation result, if the auth throws exception with the invalid api key code occurs when signing in",
      () async {
        const invalidApiKeyException = FirebaseAuthException(
          FirebaseAuthExceptionCode.invalidApiKey,
          message,
        );
        whenCreateFirebaseAuth().thenReturn(firebaseAuth);
        whenSignIn().thenAnswer((_) => Future.error(invalidApiKeyException));

        final result = await delegate.validatePublicApiKey(apiKey);

        expect(result.isFailure, isTrue);
      },
    );

    test(
      ".validatePublicApiKey() returns a result with the 'api key invalid' additional context, if the auth throws exception with the invalid api key code occurs when signing in",
      () async {
        const invalidApiKeyException = FirebaseAuthException(
          FirebaseAuthExceptionCode.invalidApiKey,
          message,
        );
        whenCreateFirebaseAuth().thenReturn(firebaseAuth);
        whenSignIn().thenAnswer((_) => Future.error(invalidApiKeyException));

        final result = await delegate.validatePublicApiKey(apiKey);

        expect(result.additionalContext, FirestoreStrings.apiKeyInvalid);
      },
    );

    test(
      ".validatePublicApiKey() returns a successful field validation result if the auth throws a Firebase auth exception with the exception code not equal to the invalid api key code when signing in",
      () async {
        whenCreateFirebaseAuth().thenReturn(firebaseAuth);

        final exceptionCodes = FirebaseAuthExceptionCode.values
            .where((code) => code != FirebaseAuthExceptionCode.invalidApiKey);

        for (final exceptionCode in exceptionCodes) {
          final exception = FirebaseAuthException(exceptionCode, message);
          whenSignIn().thenAnswer((_) => Future.error(exception));

          final result = await delegate.validatePublicApiKey(apiKey);

          expect(result.isSuccess, isTrue);
        }
      },
    );

    test(
      ".validatePublicApiKey() returns a successful field validation result if the sign in succeeds",
      () async {
        whenCreateFirebaseAuth().thenReturn(firebaseAuth);
        whenSignIn().thenAnswer((_) => Future.value(user));

        final result = await delegate.validatePublicApiKey(apiKey);

        expect(result.isSuccess, isTrue);
      },
    );

    test(
      ".validateAuth() creates a firebase auth with the firebase auth factory",
      () {
        whenCreateFirebaseAuth().thenReturn(firebaseAuth);

        delegate.validateAuth(credentials);

        verify(authFactory.create(apiKey)).called(1);
      },
    );

    test(
      ".validateAuth() signs in with the created firebase auth and the given credentials",
      () {
        final expectedEmail = credentials.email;
        final expectedPassword = credentials.password;
        whenCreateFirebaseAuth().thenReturn(firebaseAuth);

        delegate.validateAuth(credentials);

        verify(firebaseAuth.signIn(expectedEmail, expectedPassword)).called(1);
      },
    );
  });
}

class _FirebaseAuthFactoryMock extends Mock implements FirebaseAuthFactory {}

class _FirestoreFactoryMock extends Mock implements FirestoreFactory {}

class _FirebaseAuthMock extends Mock implements FirebaseAuth {}
