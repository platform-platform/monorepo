// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:metrics/auth/domain/entities/authentication_exception.dart';
import 'package:metrics/auth/domain/usecases/parameters/user_credentials_param.dart';
import 'package:metrics/auth/domain/usecases/sign_in_usecase.dart';
import 'package:metrics_core/metrics_core.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../../test_utils/matchers.dart';
import '../../../test_utils/user_repository_mock.dart';

void main() {
  group("SignInUseCase", () {
    final repository = UserRepositoryMock();

    tearDown(() {
      reset(repository);
    });

    final userCredentials = UserCredentialsParam(
      email: Email('email@mail.mail'),
      password: Password('password'),
    );

    test("throws an AssertionError if the given repository is null", () {
      expect(
        () => SignInUseCase(null),
        throwsAssertionError,
      );
    });

    test(
      "delegates call to the UserRepository.signInWithEmailAndPassword",
      () async {
        final signInUseCase = SignInUseCase(repository);

        await signInUseCase(userCredentials);

        verify(repository.signInWithEmailAndPassword(
          userCredentials.email.value,
          userCredentials.password.value,
        )).called(once);
      },
    );

    test(
      "throws if UserRepository throws during sign in process",
      () {
        final signInUseCase = SignInUseCase(repository);

        when(repository.signInWithEmailAndPassword(any, any))
            .thenThrow(const AuthenticationException());

        expect(
          () => signInUseCase(userCredentials),
          throwsAuthenticationException,
        );
      },
    );
  });
}
