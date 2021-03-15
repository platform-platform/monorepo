// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:metrics/auth/domain/entities/auth_credentials.dart';
import 'package:metrics/auth/domain/entities/authentication_exception.dart';
import 'package:metrics/auth/domain/entities/email_domain_validation_result.dart';
import 'package:metrics/auth/domain/usecases/google_sign_in_usecase.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../../test_utils/matchers.dart';
import '../../../test_utils/user_repository_mock.dart';

void main() {
  group("GoogleSignInUseCase", () {
    final repository = UserRepositoryMock();
    final authCredentials = AuthCredentials(
      email: 'email',
      accessToken: 'access',
      idToken: 'idToken',
    );

    /// Get an instance of the [EmailDomainValidationResult]
    /// with the given [isValid] validation status.
    EmailDomainValidationResult getValidationResult({bool isValid}) {
      return EmailDomainValidationResult(isValid: isValid);
    }

    PostExpectation<Future<EmailDomainValidationResult>>
        whenValidateEmailDomain() {
      when(repository.getGoogleSignInCredentials()).thenAnswer(
        (_) => Future.value(authCredentials),
      );
      return when(repository.validateEmailDomain(any));
    }

    tearDown(() {
      reset(repository);
    });

    test("throws an AssertionError if the given repository is null", () {
      expect(
        () => GoogleSignInUseCase(null),
        throwsAssertionError,
      );
    });

    test(
      "throws if the UserRepository throws during getting the google sign-in credentials",
      () {
        when(repository.getGoogleSignInCredentials()).thenThrow(
          const AuthenticationException(),
        );

        final signInUseCase = GoogleSignInUseCase(repository);

        expect(() => signInUseCase(), throwsAuthenticationException);
      },
    );

    test(
      "throws if the UserRepository throws during validating an email domain",
      () {
        whenValidateEmailDomain().thenThrow(const AuthenticationException());

        final signInUseCase = GoogleSignInUseCase(repository);

        expect(() => signInUseCase(), throwsAuthenticationException);
      },
    );

    test(
      "gets the google sign-in credentials from the UserRepository",
      () async {
        whenValidateEmailDomain().thenAnswer(
          (_) => Future.value(getValidationResult(isValid: true)),
        );

        final signInUseCase = GoogleSignInUseCase(repository);

        await signInUseCase();

        verify(repository.getGoogleSignInCredentials()).called(equals(1));
      },
    );

    test("validates the email domain", () async {
      whenValidateEmailDomain().thenAnswer(
        (_) => Future.value(getValidationResult(isValid: true)),
      );

      final signInUseCase = GoogleSignInUseCase(repository);

      await signInUseCase();

      verify(repository.validateEmailDomain(any)).called(equals(1));
    });

    test("throws if an email domain is not valid", () async {
      whenValidateEmailDomain().thenAnswer(
        (_) => Future.value(getValidationResult(isValid: false)),
      );

      final signInUseCase = GoogleSignInUseCase(repository);

      expect(
        () => signInUseCase(),
        throwsAuthenticationException,
      );
    });

    test(
      "does not call the sign-in with Google if the email domain is not valid",
      () async {
        whenValidateEmailDomain().thenAnswer(
          (_) => Future.value(getValidationResult(isValid: false)),
        );

        final signInUseCase = GoogleSignInUseCase(repository);
        await expectLater(
          signInUseCase(),
          throwsAuthenticationException,
        );

        verifyNever(repository.signInWithGoogle(any));
      },
    );

    test("signs out if the user email is not valid", () async {
      whenValidateEmailDomain().thenAnswer(
        (_) => Future.value(getValidationResult(isValid: false)),
      );

      final signInUseCase = GoogleSignInUseCase(repository);
      await expectLater(
        signInUseCase(),
        throwsAuthenticationException,
      );
      verify(repository.signOut()).called(equals(1));
    });

    test(
      "signs in a user using the Google authentication",
      () async {
        whenValidateEmailDomain().thenAnswer(
          (_) => Future.value(getValidationResult(isValid: true)),
        );

        final signInUseCase = GoogleSignInUseCase(repository);

        await signInUseCase();

        verify(repository.signInWithGoogle(any)).called(equals(1));
      },
    );

    test(
      "throws if UserRepository throws during sign-in process",
      () {
        whenValidateEmailDomain().thenAnswer(
          (_) => Future.value(getValidationResult(isValid: true)),
        );
        when(repository.signInWithGoogle(any))
            .thenThrow(const AuthenticationException());

        final signInUseCase = GoogleSignInUseCase(repository);

        expect(
          () => signInUseCase(),
          throwsAuthenticationException,
        );
      },
    );
  });
}
