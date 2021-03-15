// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'dart:async';

import 'package:metrics/auth/domain/entities/user_profile.dart';
import 'package:metrics/auth/domain/usecases/receive_user_profile_updates.dart';
import 'package:metrics/common/domain/usecases/parameters/user_id_param.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../../test_utils/matchers.dart';
import '../../../test_utils/user_repository_mock.dart';

void main() {
  group("ReceiveUserProfileUpdates", () {
    const errorMessage = 'error message';
    const id = 'id';

    final repository = UserRepositoryMock();
    final userIdParam = UserIdParam(
      id: id,
    );

    tearDown(() {
      reset(repository);
    });

    test("throws an ArgumentError if the given repository is null", () {
      expect(
        () => ReceiveUserProfileUpdates(null),
        throwsArgumentError,
      );
    });

    test("delegates call to the given repository", () {
      final receiveProfileUpdates = ReceiveUserProfileUpdates(repository);

      receiveProfileUpdates(userIdParam);

      verify(repository.userProfileStream(id)).called(once);
    });

    test("throws if the given repository throws", () {
      when(repository.userProfileStream(any)).thenThrow(errorMessage);

      final receiveProfileUpdates = ReceiveUserProfileUpdates(repository);

      expect(
        () => receiveProfileUpdates(userIdParam),
        throwsA(equals(errorMessage)),
      );
    });

    test("emits an error if the repository stream emits an error", () {
      final profileController = StreamController<UserProfile>();

      profileController.addError(errorMessage);

      when(repository.userProfileStream(any)).thenAnswer(
        (_) => profileController.stream,
      );

      final receiveProfileUpdates = ReceiveUserProfileUpdates(repository);
      final profileUpdates = receiveProfileUpdates(userIdParam);

      expect(
        profileUpdates,
        emitsError(equals(errorMessage)),
      );
    });
  });
}
