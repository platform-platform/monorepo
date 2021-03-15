// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:metrics/auth/domain/entities/theme_type.dart';
import 'package:metrics/auth/presentation/models/user_profile_model.dart';
import 'package:test/test.dart';

import '../../../test_utils/matchers.dart';

void main() {
  group("UserProfileModel", () {
    const id = 'id';
    const selectedTheme = ThemeType.dark;

    test("throws an AssertionError if the given selected theme is null", () {
      expect(
        () => UserProfileModel(id: id, selectedTheme: null),
        throwsAssertionError,
      );
    });

    test("creates an instance with the given parameters", () {
      const userProfileModel = UserProfileModel(
        id: id,
        selectedTheme: selectedTheme,
      );

      expect(userProfileModel.id, equals(id));
      expect(userProfileModel.selectedTheme, equals(selectedTheme));
    });

    test(
      "equals to another user profile model with the same parameters",
      () {
        const firstUserProfileModel = UserProfileModel(
          id: id,
          selectedTheme: selectedTheme,
        );

        const secondUserProfileModel = UserProfileModel(
          id: id,
          selectedTheme: selectedTheme,
        );

        expect(
          firstUserProfileModel,
          equals(secondUserProfileModel),
        );
      },
    );

    test(
      ".merge() returns the same instance if the given user profile model is null",
      () {
        const firstUserProfileModel = UserProfileModel(
          id: id,
          selectedTheme: selectedTheme,
        );

        final secondUserProfileModel = firstUserProfileModel.merge(null);

        expect(firstUserProfileModel, equals(secondUserProfileModel));
      },
    );

    test(
      ".merge() creates a new instance with the given fields replaced with the new values",
      () {
        const selectedTheme = ThemeType.light;

        const firstUserProfileModel = UserProfileModel(
          id: id,
          selectedTheme: ThemeType.dark,
        );

        const secondUserProfileModel = UserProfileModel(
          id: id,
          selectedTheme: selectedTheme,
        );

        final mergedUserProfileModel = firstUserProfileModel.merge(
          secondUserProfileModel,
        );

        expect(
          mergedUserProfileModel.id,
          equals(firstUserProfileModel.id),
        );
        expect(mergedUserProfileModel.selectedTheme, equals(selectedTheme));
      },
    );

    test(
      ".copyWith() creates a new instance with the same fields if called without params",
      () {
        const firstUserProfileModel = UserProfileModel(
          id: id,
          selectedTheme: selectedTheme,
        );

        final secondProfileModel = firstUserProfileModel.copyWith();

        expect(firstUserProfileModel, equals(secondProfileModel));
      },
    );

    test(
      ".copyWith() creates a copy of an instance with the given fields replaced with the new values",
      () {
        const selectedTheme = ThemeType.light;

        const firstUserProfileModel = UserProfileModel(
          id: id,
          selectedTheme: selectedTheme,
        );

        final copiedUserProfileModel = firstUserProfileModel.copyWith(
          selectedTheme: selectedTheme,
        );

        expect(
          copiedUserProfileModel.id,
          equals(firstUserProfileModel.id),
        );
        expect(copiedUserProfileModel.selectedTheme, equals(selectedTheme));
      },
    );
  });
}
