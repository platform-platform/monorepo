// Use of this source code is governed by the Apache License, Version 2.0
// that can be found in the LICENSE file.

import 'package:metrics/analytics/domain/usecases/log_login_use_case.dart';
import 'package:metrics/common/domain/usecases/parameters/user_id_param.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../../test_utils/analytics_repository_mock.dart';
import '../../../test_utils/matchers.dart';

void main() {
  group("LogLoginUseCase", () {
    final repository = AnalyticsRepositoryMock();

    tearDown(() {
      reset(repository);
    });

    const id = 'id';
    final userIdParam = UserIdParam(id: id);

    test("throws an ArgumentError if the given repository is null", () {
      expect(
        () => LogLoginUseCase(null),
        throwsArgumentError,
      );
    });

    test("sets the user identifier to the given value", () async {
      final logLoginUseCase = LogLoginUseCase(repository);

      await logLoginUseCase(userIdParam);

      verify(repository.setUserId(id)).called(once);
    });

    test("logs user logins", () async {
      final logLoginUseCase = LogLoginUseCase(repository);

      await logLoginUseCase(userIdParam);

      verify(repository.logLogin()).called(once);
    });
  });
}
