// Use of this source code is governed by the Apache License, Version 2.0 
// that can be found in the LICENSE file.

import 'package:metrics/auth/domain/entities/authentication_exception.dart';
import 'package:metrics/auth/domain/usecases/sign_out_usecase.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../../test_utils/matchers.dart';
import '../../../test_utils/user_repository_mock.dart';

void main() {
  group("SignOutUseCase", () {
    final repository = UserRepositoryMock();

    tearDown(() {
      reset(repository);
    });

    test("throws an AssertionError if the given repository is null", () {
      expect(
        () => SignOutUseCase(null),
        throwsAssertionError,
      );
    });

    test("delegates call to the UserRepository.signOut", () async {
      final signOutUseCase = SignOutUseCase(repository);

      await signOutUseCase();

      verify(repository.signOut()).called(equals(1));
    });

    test(
      "throws if UserRepository throws during sign out",
      () {
        final signOutUseCase = SignOutUseCase(repository);

        when(repository.signOut()).thenThrow(const AuthenticationException());

        expect(
          () => signOutUseCase(),
          throwsAuthenticationException,
        );
      },
    );
  });
}
