// Use of this source code is governed by the Apache License, Version 2.0 
// that can be found in the LICENSE file.

import 'package:metrics/auth/domain/entities/authentication_exception.dart';
import 'package:metrics/auth/domain/usecases/receive_authentication_updates.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../../test_utils/matchers.dart';
import '../../../test_utils/user_repository_mock.dart';

void main() {
  group("ReceiveAuthenticationUpdates", () {
    final repository = UserRepositoryMock();

    tearDown(() {
      reset(repository);
    });

    test("throws an AssertionError if the given repository is null", () {
      expect(
        () => ReceiveAuthenticationUpdates(null),
        throwsAssertionError,
      );
    });

    test("delegates call to the UserRepository.authenticationStream", () async {
      final receiveUserUpdates = ReceiveAuthenticationUpdates(repository);

      receiveUserUpdates();

      verify(repository.authenticationStream()).called(equals(1));
    });

    test(
      "throws an exception if repository throws",
      () {
        final receiveUserUpdates = ReceiveAuthenticationUpdates(repository);

        when(repository.authenticationStream())
            .thenThrow(const AuthenticationException());

        expect(
          () => receiveUserUpdates(),
          throwsAuthenticationException,
        );
      },
    );
  });
}
