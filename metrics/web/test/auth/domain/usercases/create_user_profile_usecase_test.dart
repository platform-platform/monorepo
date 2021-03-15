// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:metrics/auth/domain/entities/theme_type.dart';
import 'package:metrics/auth/domain/usecases/create_user_profile_usecase.dart';
import 'package:metrics/auth/domain/usecases/parameters/user_profile_param.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../../test_utils/matchers.dart';
import '../../../test_utils/user_repository_mock.dart';

void main() {
  group("CreateUserProfileUseCase", () {
    final repository = UserRepositoryMock();
    const id = 'id';
    const selectedTheme = ThemeType.dark;
    final userProfileParam = UserProfileParam(
      id: id,
      selectedTheme: selectedTheme,
    );

    tearDown(() {
      reset(repository);
    });

    test("throws an ArgumentError if the given repository is null", () {
      expect(
        () => CreateUserProfileUseCase(null),
        throwsArgumentError,
      );
    });

    test("delegates call to the given repository", () {
      final createProfile = CreateUserProfileUseCase(repository);

      createProfile(userProfileParam);

      verify(repository.createUserProfile(id, selectedTheme)).called(once);
    });

    test("throws if the given repository throws during creating profile", () {
      const errorMessage = 'error message';

      when(repository.createUserProfile(any, any)).thenAnswer(
        (_) => Future.error(errorMessage),
      );

      final createProfile = CreateUserProfileUseCase(repository);

      expect(
        createProfile(userProfileParam),
        throwsA(equals(errorMessage)),
      );
    });
  });
}
