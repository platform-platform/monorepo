// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:metrics/analytics/domain/usecases/reset_user_use_case.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../../test_utils/analytics_repository_mock.dart';
import '../../../test_utils/matchers.dart';

void main() {
  group("ResetUserUseCase", () {
    final repository = AnalyticsRepositoryMock();

    tearDown(() {
      reset(repository);
    });

    test("throws an ArgumentError if the given repository is null", () {
      expect(
        () => ResetUserUseCase(null),
        throwsArgumentError,
      );
    });

    test("sets the user identifier to the null", () async {
      final resetUserUseCase = ResetUserUseCase(repository);

      await resetUserUseCase();

      verify(repository.setUserId(null)).called(once);
    });
  });
}
